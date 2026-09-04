function adaptiveRiskMap = applyAdaptiveSafetyEnvelope(riskMap, acarg, cfg)
%APPLYADAPTIVESAFETYENVELOPE Reconstruct occupancy with per-actor ACARG margins.
%   Preferred approach: iterates over actor predictions from the Phase 4
%   riskMap and recomputes uncertainty footprints with per-actor ACARG
%   safety scales.  The original Phase 4 riskMap is NOT modified.
%
%   Architecture:
%       Phase 4 actorPredictions  +  ACARG per-actor safety scales
%           → scaled uncertainty footprints per actor per time step
%           → rasterised into fresh occupancy map
%           → conservative union
%           → Phase 5 createPlanner consumes this map
%
%   Inflation correction:
%       Phase 4 envelopes already include base safety margins.
%       ACARG scaling is multiplicative on the envelope SemiAxes:
%           scaledAxes = baseAxes × actorSafetyScale
%       where actorSafetyScale >= 1.0.  The additional inflation
%       beyond baseline is: baseAxes × (safetyScale - 1).
%       This avoids the double-counting problem of inflating an
%       already-inflated map.

    [protoMap, metadata] = createOccupancyMap(cfg);
    times = riskMap.times;
    conservativeMask = false(metadata.GridSize);
    conservativeRisk = zeros(metadata.GridSize);

    % Build per-actor safety scale lookup from ACARG decision
    scaleLookup = buildScaleLookup(acarg, cfg);

    % Retrieve the actor predictions stored by Phase 4
    actorPredictions = riskMap.actorPredictions;
    egoPosition = positionOf(riskMap.egoState);

    for layerIndex = 1:numel(times)
        [layerMap, ~] = createOccupancyMap(cfg);
        layerRisk = zeros(metadata.GridSize);
        layerMask = false(metadata.GridSize);

        for predIndex = 1:numel(actorPredictions)
            pred = actorPredictions{predIndex};
            prediction = pred.Prediction;

            if layerIndex > numel(prediction.Time)
                continue;
            end

            state = [prediction.Position(layerIndex, :).'; ...
                prediction.Velocity(layerIndex, :).'];
            covariance = prediction.Covariance(:, :, layerIndex);
            actorClass = pred.Class;

            % Compute base Phase 4 envelope
            envelope = computeUncertaintyFootprint(state, covariance, ...
                actorClass, cfg);

            % Apply per-actor ACARG safety scale
            scale = lookupScale(scaleLookup, pred.ActorID);
            if scale > 1.0
                envelope.SemiAxes = envelope.SemiAxes * scale;
            end

            % Risk contribution — use ACARG actor risk directly if available
            risk = lookupRisk(scaleLookup, pred.ActorID);
            risk = min(1, max(0, risk));

            [layerMap, layerRisk, actorMask] = inflateRiskMap(layerMap, ...
                layerRisk, envelope, risk, metadata);
            layerMask = layerMask | actorMask;
        end

        conservativeMask = conservativeMask | layerMask;
        conservativeRisk = max(conservativeRisk, layerRisk);
    end

    % Set occupied cells in the prototype map
    if any(conservativeMask(:))
        [xGrid, yGrid] = meshgrid(metadata.XCenters, metadata.YCenters);
        setOccupancy(protoMap, [xGrid(conservativeMask), yGrid(conservativeMask)], ...
            true(nnz(conservativeMask), 1));
    end

    % Build adaptive riskMap — preserves Phase 4 structure compatibility
    adaptiveRiskMap = riskMap;
    adaptiveRiskMap.staticConservativeMap  = protoMap;
    adaptiveRiskMap.conservativeOccupancyMask = conservativeMask;
    adaptiveRiskMap.conservativeRiskGrid   = conservativeRisk;
    adaptiveRiskMap.adaptiveEnvelopeApplied = true;
end

%% ---- per-actor scale lookup ----

function lookup = buildScaleLookup(acarg, cfg)
%BUILDSCALELOOKUP Create a map from ActorID → safetyScale and risk.
    lookup = struct('ids', [], 'scales', [], 'risks', []);
    if ~isfield(acarg, 'risk') || ~isfield(acarg.risk, 'actorRisk')
        return;
    end
    actorRisks = acarg.risk.actorRisk;
    n = numel(actorRisks);
    ids    = zeros(1, n);
    scales = ones(1, n);
    risks  = zeros(1, n);

    % Global state multiplier
    stateMultiplier = 1.0;
    if isfield(cfg, 'governor') && isfield(cfg.governor, 'safetyEnvelope') && ...
            isfield(cfg.governor.safetyEnvelope, 'stateScale') && ...
            isfield(acarg, 'state')
        stateScales = cfg.governor.safetyEnvelope.stateScale;
        stateKey = upper(char(acarg.state));
        if isfield(stateScales, stateKey)
            stateMultiplier = stateScales.(stateKey);
        end
    end

    for i = 1:n
        ar = actorRisks(i);
        ids(i)    = readField(ar, {'ActorID'}, 0);
        baseScale = readField(ar, {'safetyScale'}, 1.0);
        scales(i) = baseScale * stateMultiplier;
        risks(i)  = readField(ar, {'risk'}, 0);
    end
    lookup.ids    = ids;
    lookup.scales = scales;
    lookup.risks  = risks;
end

function scale = lookupScale(lookup, actorID)
    idx = find(lookup.ids == actorID, 1);
    if isempty(idx)
        scale = 1.0;
    else
        scale = lookup.scales(idx);
    end
end

function risk = lookupRisk(lookup, actorID)
    idx = find(lookup.ids == actorID, 1);
    if isempty(idx)
        risk = 0.5;   % conservative default
    else
        risk = lookup.risks(idx);
    end
end

%% ---- local helpers ----

function position = positionOf(egoState)
    position = readField(egoState, {'Position', 'CurrentState'}, [0 0]);
    position = double(position(:).');
    if numel(position) < 2 || any(~isfinite(position(1:2)))
        position = [0 0];
    else
        position = position(1:2);
    end
end

function value = readField(item, names, fallback)
    value = fallback;
    if ~isstruct(item)
        return;
    end
    for index = 1:numel(names)
        if isfield(item, names{index})
            value = item.(names{index});
            return;
        end
    end
end
