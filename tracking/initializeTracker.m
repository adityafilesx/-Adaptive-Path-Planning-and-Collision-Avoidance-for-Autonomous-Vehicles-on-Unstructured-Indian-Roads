function track = initializeTracker(detection, dt, config, currentTime)
%INITIALIZETRACKER Initialize one actor track from a valid perception record.
%   The public track structure is identical whether trackingKF is available
%   or the portable local constant-velocity Kalman filter is selected.

    if nargin < 4
        currentTime = 0;
    end
    cfg = trackingConfig(config);
    if ~isValidDetection(detection)
        error('initializeTracker:InvalidDetection', ...
            'A tracker requires a detected, finite 2-D position.');
    end

    classParameters = classParametersFor(detection, cfg);
    position = row2(detection.Position);
    velocity = row2(readField(detection, {'Velocity'}, [0 0]));
    if any(~isfinite(velocity))
        velocity = [0 0];
    end
    state = [position(1); position(2); velocity(1); velocity(2)];
    positionVariance = max(readPositionVariance(detection), ...
        classParameters.InitialPositionVariance);
    covariance = diag([positionVariance, positionVariance, ...
        classParameters.InitialVelocityVariance, ...
        classParameters.InitialVelocityVariance]);
    processNoise = cfg.defaultProcessNoise * classParameters.ProcessNoiseScale;
    measurementNoise = measurementCovariance(detection, cfg);

    localTracker = struct('Backend', 'localCV', 'State', state, ...
        'StateCovariance', covariance, 'MeasurementModel', [1 0 0 0; 0 1 0 0], ...
        'MeasurementNoise', measurementNoise, 'ProcessNoise', processNoise);
    tracker = tryTrackingKF(localTracker, cfg);
    perceivedClass = readField(detection, {'PerceivedClass'}, []);
    if isempty(perceivedClass)
        perceivedClass = readField(detection, {'TrueClass'}, []);
    end

    track = struct('ActorID', readField(detection, {'ID', 'ActorID'}, []), ...
        'TrueClass', readField(detection, {'TrueClass'}, []), ...
        'PerceivedClass', perceivedClass, 'Tracker', tracker, ...
        'LastUpdateTime', currentTime, 'MissedDetectionCount', 0, ...
        'DetectionCount', 1, 'Confidence', bounded(readField(detection, ...
        {'Confidence'}, 1)), 'TrackingConfidence', bounded(readField( ...
        detection, {'Confidence'}, 1)), 'CurrentState', state, ...
        'CurrentCovariance', covariance, 'ProcessNoise', processNoise, ...
        'MaxMissedDetections', classParameters.MaxMissedDetections, ...
        'ClassParameters', classParameters, 'LastMeasurementUsed', true, ...
        'IsStale', false, 'SampleTime', dt);
end

function tracker = tryTrackingKF(localTracker, cfg)
    tracker = localTracker;
    if ~cfg.preferTrackingKF || exist('trackingKF', 'file') ~= 2
        return;
    end
    try
        filter = trackingKF('MotionModel', '2D Constant Velocity', ...
            'State', localTracker.State, ...
            'StateCovariance', localTracker.StateCovariance, ...
            'MeasurementModel', localTracker.MeasurementModel, ...
            'MeasurementNoise', localTracker.MeasurementNoise);
        if isprop(filter, 'ProcessNoise')
            filter.ProcessNoise = localTracker.ProcessNoise;
        end
        tracker.Backend = 'trackingKF';
        tracker.Filter = filter;
    catch
        % Constructor signatures differ by release; retain portable fallback.
    end
end

function cfg = trackingConfig(config)
    if isfield(config, 'tracking')
        cfg = config.tracking;
    else
        cfg = config;
    end
    required = {'defaultProcessNoise', 'defaultPositionVariance', ...
        'defaultVelocityVariance', 'minimumMeasurementVariance', ...
        'maxMissedDetections', 'preferTrackingKF', 'classParameters'};
    for index = 1:numel(required)
        if ~isfield(cfg, required{index})
            error('initializeTracker:MissingConfiguration', ...
                'Missing tracking configuration field: %s.', required{index});
        end
    end
    if ~isfield(cfg, 'classIDMap')
        cfg.classIDMap = struct();
    end
end

function parameters = classParametersFor(detection, cfg)
    classValue = readField(detection, {'PerceivedClass'}, []);
    if isempty(classValue)
        classValue = readField(detection, {'TrueClass'}, []);
    end
    key = classKey(classValue, cfg.classIDMap);
    if isfield(cfg.classParameters, key)
        parameters = cfg.classParameters.(key);
    else
        parameters = cfg.classParameters.default;
    end
end

function key = classKey(value, classIDMap)
    if isnumeric(value) && isscalar(value) && isfinite(value)
        numericKey = sprintf('id%d', value);
        if isfield(classIDMap, numericKey)
            value = classIDMap.(numericKey);
        else
            key = numericKey;
            return;
        end
    end
    if isstring(value)
        value = char(value);
    end
    if ~ischar(value)
        key = 'default';
        return;
    end
    key = lower(regexprep(value, '[^a-zA-Z0-9_]', ''));
    if isempty(key)
        key = 'default';
    end
end

function variance = readPositionVariance(detection)
    std = row2(readField(detection, {'PositionStd'}, [NaN NaN]));
    variance = std .^ 2;
    variance(~isfinite(variance)) = 0;
    variance = max(variance);
end

function covariance = measurementCovariance(detection, cfg)
    std = row2(readField(detection, {'PositionStd'}, [NaN NaN]));
    variance = std .^ 2;
    variance(~isfinite(variance)) = cfg.minimumMeasurementVariance;
    covariance = diag(max(variance, cfg.minimumMeasurementVariance));
end

function tf = isValidDetection(detection)
    tf = logical(readField(detection, {'IsDetected'}, true));
    position = row2(readField(detection, {'Position'}, [NaN NaN]));
    tf = tf && all(isfinite(position));
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

function value = row2(value)
    value = double(value(:).');
    if isempty(value)
        value = [NaN NaN];
    elseif numel(value) == 1
        value = [value value];
    end
    value = value(1:2);
end

function value = bounded(value)
    value = min(1, max(0, value));
end
