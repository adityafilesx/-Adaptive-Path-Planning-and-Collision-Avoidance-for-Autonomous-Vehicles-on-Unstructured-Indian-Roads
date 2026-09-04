function [risk, diagnostics] = computeCollisionRisk(track, prediction, egoState, egoPath, cfg)
%COMPUTECOLLISIONRISK Bounded collision risk using predicted trajectory + 2D CPA.
%   Evaluates the actor's predicted trajectory against the ego position
%   (and optionally the ego path) to estimate collision proximity.
%
%   Hierarchy:
%       1. If a predicted trajectory is available (Phase 3 prediction),
%          evaluate predicted positions for minimum separation and
%          time-to-minimum-separation.
%       2. Fallback: 2D CPA using current position/velocity.
%
%   Output: risk ∈ [0,1]

    gcfg = governorSubConfig(cfg, 'risk');

    egoPos = safeVec2(positionOf(egoState));
    egoVel = safeVec2(velocityOf(egoState));

    % ---- predicted trajectory risk (preferred) ----
    if ~isempty(prediction) && isfield(prediction, 'Position') && ...
            size(prediction.Position, 1) > 1
        [risk, diagnostics] = predictedTrajectoryRisk( ...
            prediction, egoPos, egoVel, egoPath, gcfg);
        return;
    end

    % ---- fallback: 2D CPA from current state ----
    state = readField(track, {'CurrentState'}, [0; 0; 0; 0]);
    actorPos = state(1:2).';
    actorVel = state(3:4).';
    cpa = computeTTC(actorPos, actorVel, egoPos, egoVel);
    risk = cpaToRisk(cpa, gcfg);
    diagnostics = diagnosticStruct('current-state CPA', ...
        norm(actorPos - egoPos), norm(actorPos - egoPos), 0, cpa, ...
        exp(-norm(actorPos - egoPos) / max(eps, gcfg.cpaSafeDistance)), ...
        risk, NaN, risk);
end

%% ---- predicted trajectory evaluation ----

function [risk, diagnostics] = predictedTrajectoryRisk( ...
        prediction, egoPos, egoVel, egoPath, gcfg)
%PREDICTEDTRAJECTORYRISK Minimum separation from predicted actor positions.
    nSteps = min(size(prediction.Position, 1), gcfg.maxPredictionSteps);
    minDist = inf;
    minTime = inf;
    bestCPA = struct('tCPA', inf, 'dCPA', inf, 'relativeSpeed', 0, 'isClosing', false);

    % If an ego path is available, compare against path waypoints
    if ~isempty(egoPath) && isfield(egoPath, 'states') && size(egoPath.states, 1) > 1
        pathXY = egoPath.states(:, 1:2);
    else
        pathXY = [];
    end

    for step = 1:nSteps
        actorXY = prediction.Position(step, 1:2);
        actorVel = prediction.Velocity(step, 1:2);
        dt = prediction.Time(step);

        % Distance to ego position
        d = norm(actorXY - egoPos);
        if d < minDist
            minDist = d;
            minTime = dt;
        end

        % Distance to closest path point (if available)
        if ~isempty(pathXY)
            dPath = sqrt(sum((pathXY - actorXY).^2, 2));
            dMinPath = min(dPath);
            if dMinPath < minDist
                minDist = dMinPath;
                minTime = dt;
            end
        end

        % 2D CPA at this prediction step
        egoFuturePos = egoPos + egoVel * dt;
        cpa = computeTTC(actorXY, actorVel, egoFuturePos, egoVel);
        if cpa.dCPA < bestCPA.dCPA
            bestCPA = cpa;
        end
    end

    % Combine distance proximity and CPA
    distRisk = exp(-minDist / max(eps, gcfg.cpaSafeDistance));
    cpaRisk  = cpaToRisk(bestCPA, gcfg);
    timeRisk = 0;
    if isfinite(minTime) && minTime > 0
        timeRisk = exp(-minTime / gcfg.ttcScale);
    elseif minTime == 0
        timeRisk = 1.0;
    end

    % Time-to-minimum separation is an urgency modifier, not independent
    % evidence of collision.  In particular, minTime==0 commonly means the
    % actor is currently at its closest predicted point while remaining far
    % away; allowing timeRisk alone to dominate would assign collisionRisk=1.
    timeWeightedDistanceRisk = distRisk * timeRisk;
    risk = max(timeWeightedDistanceRisk, cpaRisk);
    risk = min(1, max(0, risk));
    diagnostics = diagnosticStruct('predicted trajectory', ...
        norm(prediction.Position(1, 1:2) - egoPos), minDist, minTime, ...
        bestCPA, distRisk, cpaRisk, timeRisk, risk);
    diagnostics.timeWeightedDistanceComponent = timeWeightedDistanceRisk;
end

function diagnostics = diagnosticStruct(method, physicalDistance, ...
        minimumPredictedDistance, minimumPredictionTime, cpa, ...
        distanceComponent, cpaComponent, timeComponent, finalRisk)
    diagnostics = struct('method', method, ...
        'physicalDistance', physicalDistance, ...
        'minimumPredictedDistance', minimumPredictedDistance, ...
        'minimumPredictionTime', minimumPredictionTime, ...
        'cpaTime', cpa.tCPA, 'cpaDistance', cpa.dCPA, ...
        'relativeSpeed', cpa.relativeSpeed, 'isClosing', cpa.isClosing, ...
        'distanceComponent', distanceComponent, ...
        'cpaComponent', cpaComponent, 'timeComponent', timeComponent, ...
        'timeWeightedDistanceComponent', distanceComponent * timeComponent, ...
        'finalCollisionRisk', finalRisk);
end

%% ---- CPA to risk conversion ----

function risk = cpaToRisk(cpa, gcfg)
%CPATORISK Convert CPA struct to bounded risk score.
    if ~cpa.isClosing || cpa.dCPA > gcfg.cpaSafeDistance * 3
        risk = 0;
        return;
    end
    distComponent = exp(-cpa.dCPA / max(eps, gcfg.cpaSafeDistance));
    if cpa.tCPA > 0 && isfinite(cpa.tCPA)
        timeComponent = exp(-cpa.tCPA / gcfg.ttcScale);
    else
        timeComponent = 1.0;
    end
    risk = max(distComponent, timeComponent);
    risk = min(1, max(0, risk));
end

%% ---- local helpers ----

function gcfg = governorSubConfig(cfg, subField)
    if isfield(cfg, 'governor') && isfield(cfg.governor, subField)
        gcfg = cfg.governor.(subField);
    else
        error('computeCollisionRisk:MissingConfig', ...
            'cfg.governor.%s is required.', subField);
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

function vec = safeVec2(value)
    value = double(value(:).');
    if numel(value) < 2
        vec = [0 0];
    else
        vec = value(1:2);
    end
    vec(~isfinite(vec)) = 0;
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
