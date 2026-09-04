function riskMap = updateOccupancyMap(tracks, egoState, config)
%UPDATEOCCUPANCYMAP Build time-indexed dynamic occupancy and risk layers.
%   TRACKS uses the public Phase 3 track structure. Each temporal layer is
%   a binaryOccupancyMap plus a separate normalized (not probabilistic) risk
%   grid. The conservative map is their spatial union for planner hand-off.

    cfg = fullConfig(config);
    [prototypeMap, metadata] = createOccupancyMap(cfg);
    times = predictionTimes(cfg.prediction.horizon, cfg.prediction.dt);
    layerTemplate = struct('Time', 0, 'OccupancyMap', [], 'RiskGrid', [], ...
        'OccupancyMask', [], 'ActorContributions', {{}});
    layers = repmat(layerTemplate, numel(times), 1);
    conservativeMask = false(metadata.GridSize);
    conservativeRisk = zeros(metadata.GridSize);
    actorPredictions = cell(0, 1);
    egoPosition = positionOf(egoState);

    for layerIndex = 1:numel(times)
        [layerMap, ~] = createOccupancyMap(cfg);
        layerRisk = zeros(metadata.GridSize);
        layerMask = false(metadata.GridSize);
        contributions = cell(0, 1);
        for actorIndex = 1:numel(tracks)
            track = tracks(actorIndex);
            if ~eligibleTrack(track, cfg)
                continue;
            end
            prediction = predictionForTrack(track, cfg);
            if layerIndex > numel(prediction.Time)
                continue;
            end
            state = [prediction.Position(layerIndex, :).'; ...
                prediction.Velocity(layerIndex, :).'];
            covariance = prediction.Covariance(:, :, layerIndex);
            actorClass = classOf(track);
            envelope = computeUncertaintyFootprint(state, covariance, actorClass, cfg);
            risk = riskContribution(envelope, state, egoPosition, times(layerIndex), cfg);
            [layerMap, layerRisk, actorMask] = inflateRiskMap(layerMap, ...
                layerRisk, envelope, risk, metadata);
            layerMask = layerMask | actorMask;
            contributions{end + 1, 1} = struct('ActorID', actorIDOf(track), ...
                'Class', actorClass, 'State', state, 'Covariance', covariance, ...
                'Envelope', envelope, 'RiskContribution', risk); %#ok<AGROW>
            if layerIndex == 1
                actorPredictions{end + 1, 1} = struct('ActorID', actorIDOf(track), ...
                    'Class', actorClass, 'Prediction', prediction); %#ok<AGROW>
            end
        end
        layers(layerIndex) = struct('Time', times(layerIndex), ...
            'OccupancyMap', layerMap, 'RiskGrid', layerRisk, ...
            'OccupancyMask', layerMask, 'ActorContributions', {contributions});
        conservativeMask = conservativeMask | layerMask;
        conservativeRisk = max(conservativeRisk, layerRisk);
    end
    if any(conservativeMask(:))
        setOccupancy(prototypeMap, worldPoints(conservativeMask, metadata), ...
            true(nnz(conservativeMask), 1));
    end
    riskMap = struct('layers', layers, 'times', times(:), ...
        'resolution', metadata.Resolution, 'cellSize', metadata.CellSize, ...
        'origin', metadata.Origin, 'metadata', metadata, ...
        'staticConservativeMap', prototypeMap, ...
        'conservativeOccupancyMask', conservativeMask, ...
        'conservativeRiskGrid', conservativeRisk, ...
        'actorPredictions', {actorPredictions}, ...
        'egoState', egoState, ...
        'riskDescription', 'normalized risk score, not collision probability');
end

function cfg = fullConfig(config)
    cfg = config;
    if ~isfield(config, 'occupancy') || ~isfield(config, 'prediction') || ...
            ~isfield(config, 'tracking')
        error('updateOccupancyMap:MissingConfiguration', ...
            'Full project configuration requires occupancy, prediction, and tracking fields.');
    end
end

function times = predictionTimes(horizon, dt)
    times = 0:dt:horizon;
    if isempty(times) || times(end) < horizon
        times(end + 1) = horizon;
    end
    times = times(:);
end

function prediction = predictionForTrack(track, cfg)
    processNoise = readField(track, {'ProcessNoise'}, ...
        cfg.tracking.defaultProcessNoise);
    covariance = readField(track, {'CurrentCovariance'}, []);
    if ~isequal(size(covariance), [4 4]) || any(~isfinite(covariance(:)))
        covariance = cfg.occupancy.invalidCovarianceVariance * eye(4);
    end
    prediction = predictActor(track.CurrentState, covariance, ...
        cfg.prediction.horizon, cfg.prediction.dt, struct('ProcessNoise', processNoise));
end

function tf = eligibleTrack(track, cfg)
    state = readField(track, {'CurrentState'}, []);
    if numel(state) < 4 || any(~isfinite(state(1:4)))
        tf = false;
        return;
    end
    missedCount = readField(track, {'MissedDetectionCount'}, 0);
    tf = missedCount <= cfg.tracking.maxPredictionWithoutDetection;
end

function value = classOf(track)
    value = readField(track, {'PerceivedClass'}, []);
    if isempty(value)
        value = readField(track, {'TrueClass'}, 'default');
    end
end

function value = actorIDOf(track)
    value = readField(track, {'ActorID', 'ID'}, []);
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

function risk = riskContribution(envelope, state, egoPosition, time, cfg)
    displacement = state(1:2).' - egoPosition;
    distance = norm(displacement);
    if displacement(1) >= 0
        regionMultiplier = cfg.occupancy.forwardRegionMultiplier;
    else
        regionMultiplier = cfg.occupancy.rearRegionMultiplier;
    end
    proximity = exp(-distance / cfg.occupancy.distanceDecayScale);
    variance = trace(envelope.PositionCovariance);
    uncertainty = min(1, variance / cfg.occupancy.uncertaintyVarianceScale);
    uncertaintyFactor = cfg.occupancy.minimumOccupancyRisk + ...
        (1 - cfg.occupancy.minimumOccupancyRisk) * uncertainty;
    timeFactor = max(0, 1 - cfg.occupancy.timeRiskDecay * time);
    risk = envelope.PhysicalFootprint.RiskWeight * uncertaintyFactor * ...
        proximity * regionMultiplier * timeFactor;
    risk = min(1, max(0, risk));
end

function points = worldPoints(mask, metadata)
    [xGrid, yGrid] = meshgrid(metadata.XCenters, metadata.YCenters);
    points = [xGrid(mask), yGrid(mask)];
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
