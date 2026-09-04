function result = computeActorRisk(track, prediction, egoState, egoPath, cfg)
%COMPUTEACTORRISK Composite per-actor risk score combining all ACARG signals.
%   Combines: class weight, uncertainty, confidence, distance, collision.
%
%   Formula:
%       rawRisk = wU*U + wC*(1-C) + wD*D + wP*P
%       risk    = min(1, classWeight * rawRisk)
%
%   Class weight is normalised internally so car = 1.0.
%
%   Output: struct with risk ∈ [0,1] and all intermediate values.

    gcfg = governorSubConfig(cfg, 'risk');

    % ---- per-actor signals ----
    confidence  = computeTrustScore(track, egoState, cfg);
    uncertainty = computeUncertaintyScore(track, cfg);

    perceivedClass = readField(track, {'PerceivedClass'}, 'unknown');
    if isempty(perceivedClass)
        perceivedClass = readField(track, {'TrueClass'}, 'unknown');
    end
    classWeight = classRiskWeights(perceivedClass, cfg);

    actorPos = safeState(track, 1:2);
    egoPos   = positionOf(egoState);
    distanceRisk  = computeDistanceRisk(actorPos, egoPos, cfg);
    [collisionRisk, collisionDiagnostics] = computeCollisionRisk( ...
        track, prediction, egoState, egoPath, cfg);

    % ---- weighted combination ----
    rawRisk = gcfg.wUncertainty * uncertainty   + ...
              gcfg.wConfidence  * (1 - confidence) + ...
              gcfg.wDistance    * distanceRisk  + ...
              gcfg.wCollision   * collisionRisk;

    risk = classWeight * rawRisk;
    risk = min(1, max(0, risk));

    % ---- per-actor safety scale ----
    envCfg = governorSubField(cfg, 'safetyEnvelope');
    actorSafetyScale = 1.0 + envCfg.riskScaling * risk;

    actorVelocity = safeState(track, 3:4);
    egoVelocity = velocityOf(egoState);
    covariance = readField(track, {'CurrentCovariance'}, []);
    if ~isequal(size(covariance), [4 4]) || any(~isfinite(covariance(:)))
        covariance = cfg.occupancy.invalidCovarianceVariance * eye(4);
    end
    envelope = computeUncertaintyFootprint( ...
        [actorPos actorVelocity].', covariance, perceivedClass, cfg);
    uncertaintyContribution = gcfg.wUncertainty * uncertainty;
    confidenceContribution = gcfg.wConfidence * (1 - confidence);
    distanceContribution = gcfg.wDistance * distanceRisk;
    collisionContribution = gcfg.wCollision * collisionRisk;

    result = struct('ActorID', readField(track, {'ActorID'}, []), ...
        'risk', risk, 'confidence', confidence, 'uncertainty', uncertainty, ...
        'collisionRisk', collisionRisk, 'distanceRisk', distanceRisk, ...
        'classWeight', classWeight, 'perceivedClass', perceivedClass, ...
        'rawRisk', rawRisk, 'safetyScale', actorSafetyScale, ...
        'position', actorPos, 'velocity', actorVelocity, ...
        'egoPosition', egoPos, 'egoVelocity', egoVelocity, ...
        'relativePosition', actorPos - egoPos, ...
        'relativeVelocity', actorVelocity - egoVelocity, ...
        'distance', norm(actorPos - egoPos), ...
        'uncertaintyContribution', uncertaintyContribution, ...
        'confidenceContribution', confidenceContribution, ...
        'distanceContribution', distanceContribution, ...
        'collisionContribution', collisionContribution, ...
        'collisionDiagnostics', collisionDiagnostics, ...
        'baseSafetyExtentX', envelope.SemiAxes(1), ...
        'baseSafetyExtentY', envelope.SemiAxes(2), ...
        'stateSafetyScale', 1, 'combinedAdaptiveScale', actorSafetyScale, ...
        'effectiveSafetyExtentX', envelope.SemiAxes(1) * actorSafetyScale, ...
        'effectiveSafetyExtentY', envelope.SemiAxes(2) * actorSafetyScale);
end

%% ---- local helpers ----

function gcfg = governorSubConfig(cfg, subField)
    if isfield(cfg, 'governor') && isfield(cfg.governor, subField)
        gcfg = cfg.governor.(subField);
    else
        error('computeActorRisk:MissingConfig', ...
            'cfg.governor.%s is required.', subField);
    end
end

function gcfg = governorSubField(cfg, subField)
    if isfield(cfg, 'governor') && isfield(cfg.governor, subField)
        gcfg = cfg.governor.(subField);
    else
        gcfg = struct();
    end
    if ~isfield(gcfg, 'riskScaling')
        gcfg.riskScaling = 1.5;
    end
end

function position = positionOf(egoState)
    position = readField(egoState, {'Position', 'CurrentState'}, [0 0]);
    position = double(position(:).');
    if numel(position) < 2 || any(~isfinite(position(1:2)))
        position = [0 0];
    else
        position = position(1:2);
    end
end

function velocity = velocityOf(egoState)
    velocity = readField(egoState, {'Velocity'}, [0 0]);
    velocity = double(velocity(:).');
    if numel(velocity) < 2 || any(~isfinite(velocity(1:2)))
        velocity = [0 0];
    else
        velocity = velocity(1:2);
    end
end

function xy = safeState(track, indices)
    state = readField(track, {'CurrentState'}, zeros(4, 1));
    state = double(state(:));
    if numel(state) < max(indices)
        xy = zeros(1, numel(indices));
    else
        xy = state(indices).';
    end
    xy(~isfinite(xy)) = 0;
end

function value = readField(item, names, fallback)
    value = fallback;
    for index = 1:numel(names)
        if isstruct(item) && isfield(item, names{index})
            value = item.(names{index});
            return;
        end
    end
end
