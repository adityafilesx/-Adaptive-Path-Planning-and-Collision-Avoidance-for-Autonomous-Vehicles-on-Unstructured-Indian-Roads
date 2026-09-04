function detections = simulatePerception(groundTruth, egoState, config)
%SIMULATEPERCEPTION Create synthetic imperfect observations from truth.
%   This is a Synthetic Sensor/Perception Layer with Controlled Uncertainty.
%   It is deliberately not a real camera, LiDAR, or neural perception system.
%   Missed observations remain in the output with IsDetected=false and NaN
%   Position/Velocity, so callers can log misses before filtering detections.

    cfg = perceptionConfig(config);
    egoPosition = statePosition(egoState);
    priorRng = [];
    if ~isempty(cfg.randomSeed)
        priorRng = rng;
        cleanup = onCleanup(@() rng(priorRng)); %#ok<NASGU>
        rng(cfg.randomSeed, 'twister');
    end

    template = emptyDetection();
    detections = repmat(template, numel(groundTruth), 1);
    for index = 1:numel(groundTruth)
        truth = groundTruth(index);
        truePosition = row3(readField(truth, {'Position'}, [NaN NaN NaN]));
        trueVelocity = row3(readField(truth, {'Velocity'}, [NaN NaN NaN]));
        distance = norm(truePosition - egoPosition);
        uncertaintyMultiplier = 1 + cfg.distanceScalingFactor * ...
            max(0, distance - cfg.distanceUncertaintyStart);
        positionStd = cfg.positionNoiseStd * uncertaintyMultiplier;
        velocityStd = cfg.velocityNoiseStd * uncertaintyMultiplier;
        isDetected = rand >= cfg.missedDetectionProbability;
        trueClass = actorClass(truth);

        detection = template;
        detection.ID = readField(truth, {'ID', 'ActorID'}, index);
        detection.TrueClass = trueClass;
        detection.Distance = distance;
        detection.PositionStd = positionStd;
        detection.VelocityStd = velocityStd;
        detection.IsDetected = isDetected;
        detection.Confidence = confidence(distance, uncertaintyMultiplier, ...
            isDetected, cfg);
        if isDetected
            detection.PerceivedClass = perturbClass(trueClass, cfg);
            detection.Position = truePosition + randn(1, 3) .* positionStd;
            detection.Velocity = trueVelocity + randn(1, 3) .* velocityStd;
        end
        detections(index) = detection;
    end
end

function detection = emptyDetection()
    detection = struct('ID', [], 'Position', [NaN NaN NaN], ...
        'Velocity', [NaN NaN NaN], 'PerceivedClass', [], 'TrueClass', [], ...
        'Distance', NaN, 'PositionStd', [NaN NaN NaN], ...
        'VelocityStd', [NaN NaN NaN], 'IsDetected', false, 'Confidence', 0);
end

function cfg = perceptionConfig(config)
    if isfield(config, 'perception')
        cfg = config.perception;
    else
        cfg = config;
    end
    required = {'positionNoiseStd', 'velocityNoiseStd', ...
        'missedDetectionProbability', 'classificationConfusionProbability', ...
        'distanceUncertaintyStart', 'distanceScalingFactor', 'randomSeed', ...
        'minimumConfidence', 'maximumConfidence'};
    for index = 1:numel(required)
        if ~isfield(cfg, required{index})
            error('simulatePerception:MissingConfiguration', ...
                'Missing perception configuration field: %s.', required{index});
        end
    end
    cfg.positionNoiseStd = row3(cfg.positionNoiseStd);
    cfg.velocityNoiseStd = row3(cfg.velocityNoiseStd);
    if ~isfield(cfg, 'classLabels')
        % Without an explicitly supplied label set, preserve the true class.
        cfg.classLabels = [];
    end
    if any(cfg.positionNoiseStd < 0) || any(cfg.velocityNoiseStd < 0) || ...
            cfg.missedDetectionProbability < 0 || cfg.missedDetectionProbability > 1 || ...
            cfg.classificationConfusionProbability < 0 || ...
            cfg.classificationConfusionProbability > 1 || cfg.distanceScalingFactor < 0 || ...
            cfg.minimumConfidence < 0 || cfg.maximumConfidence > 1 || ...
            cfg.minimumConfidence > cfg.maximumConfidence
        error('simulatePerception:InvalidConfiguration', ...
            'Perception noise/probability/confidence values are invalid.');
    end
end

function position = statePosition(egoState)
    position = row3(readField(egoState, {'Position'}, [NaN NaN NaN]));
    if any(isnan(position))
        error('simulatePerception:InvalidEgoState', ...
            'egoState must contain a finite Position with three elements.');
    end
end

function value = readField(item, names, fallback)
    value = fallback;
    for index = 1:numel(names)
        name = names{index};
        if isstruct(item) && isfield(item, name)
            value = item.(name);
            return;
        elseif ~isstruct(item) && isprop(item, name)
            value = item.(name);
            return;
        end
    end
end

function value = actorClass(truth)
    value = readField(truth, {'TrueClass', 'ClassID', 'Class', 'ActorClass'}, []);
end

function perceived = perturbClass(trueClass, cfg)
    perceived = trueClass;
    if rand >= cfg.classificationConfusionProbability || isempty(cfg.classLabels)
        return;
    end
    labels = cfg.classLabels;
    if iscell(labels)
        candidates = labels(~cellfun(@(label) isequal(label, trueClass), labels));
        if ~isempty(candidates)
            perceived = candidates{randi(numel(candidates))};
        end
    else
        candidates = labels(~arrayfun(@(label) isequal(label, trueClass), labels));
        if ~isempty(candidates)
            perceived = candidates(randi(numel(candidates)));
        end
    end
end

function value = confidence(distance, multiplier, isDetected, cfg)
    if ~isDetected
        value = 0;
        return;
    end
    % The quality decreases monotonically as the distance-driven multiplier
    % increases, while configured bounds keep reported confidence meaningful.
    quality = 1 / (1 + max(0, multiplier - 1));
    value = cfg.minimumConfidence + ...
        (cfg.maximumConfidence - cfg.minimumConfidence) * quality;
    if ~isfinite(distance)
        value = cfg.minimumConfidence;
    end
    value = min(1, max(0, value));
end

function value = row3(value)
    value = double(value(:).');
    if isempty(value)
        value = [NaN NaN NaN];
    elseif numel(value) == 1
        value = repmat(value, 1, 3);
    elseif numel(value) < 3
        value(end + 1:3) = value(end);
    end
    value = value(1:3);
end
