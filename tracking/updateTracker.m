function [track, state, covariance, trackingConfidence, measurementUsed, missedCount] = ...
        updateTracker(track, detection, dt, config, currentTime)
%UPDATETRACKER Predict and optionally correct one persistent actor track.
%   A false/absent detection triggers a prediction-only update; the track is
%   deliberately retained, including after MaxMissedDetections is exceeded.

    if nargin < 5
        currentTime = track.LastUpdateTime + dt;
    end
    cfg = trackingConfig(config);
    measurementUsed = validMeasurement(detection);
    previousState = track.CurrentState;
    previousCovariance = track.CurrentCovariance;
    transition = transitionMatrix(dt);
    predictedState = transition * previousState;
    predictedCovariance = propagateCovariance(previousCovariance, dt, ...
        track.ProcessNoise);

    [state, covariance, track] = updateWithBackend(track, detection, ...
        measurementUsed, predictedState, predictedCovariance, cfg);
    if measurementUsed
        track.MissedDetectionCount = 0;
        track.DetectionCount = track.DetectionCount + 1;
        track.Confidence = bounded(readField(detection, {'Confidence'}, ...
            track.Confidence));
        perceived = readField(detection, {'PerceivedClass'}, []);
        if ~isempty(perceived)
            track.PerceivedClass = perceived;
        end
        trueClass = readField(detection, {'TrueClass'}, []);
        if ~isempty(trueClass)
            track.TrueClass = trueClass;
        end
    else
        track.MissedDetectionCount = track.MissedDetectionCount + 1;
    end

    track.CurrentState = state;
    track.CurrentCovariance = covariance;
    track.LastUpdateTime = currentTime;
    track.LastMeasurementUsed = measurementUsed;
    track.IsStale = track.MissedDetectionCount > track.MaxMissedDetections;
    track.SampleTime = dt;
    covarianceQuality = 1 / (1 + trace(covariance(1:2, 1:2)) / ...
        cfg.confidenceCovarianceScale);
    if measurementUsed
        measurementConfidence = bounded(readField(detection, {'Confidence'}, 1));
        trackingConfidence = cfg.measurementConfidenceWeight * ...
            measurementConfidence + (1 - cfg.measurementConfidenceWeight) * ...
            covarianceQuality;
    else
        trackingConfidence = track.TrackingConfidence * ...
            cfg.missedDetectionConfidenceDecay * covarianceQuality;
    end
    track.TrackingConfidence = bounded(trackingConfidence);
    missedCount = track.MissedDetectionCount;
end

function [state, covariance, track] = updateWithBackend(track, detection, ...
        measurementUsed, predictedState, predictedCovariance, cfg)
    state = predictedState;
    covariance = predictedCovariance;
    if strcmp(track.Tracker.Backend, 'trackingKF')
        try
            predict(track.Tracker.Filter);
            if measurementUsed
                correct(track.Tracker.Filter, row2(detection.Position).');
            end
            state = track.Tracker.Filter.State;
            covariance = symmetrize(track.Tracker.Filter.StateCovariance);
            track.Tracker.State = state;
            track.Tracker.StateCovariance = covariance;
            return;
        catch
            % A release-specific filter API failed: continue with the
            % numerically equivalent portable filter and preserve the track.
            track.Tracker = localTracker(track, cfg);
        end
    end
    if measurementUsed
        measurementModel = track.Tracker.MeasurementModel;
        measurementNoise = measurementCovariance(detection, cfg);
        innovation = row2(detection.Position).' - measurementModel * state;
        innovationCovariance = measurementModel * covariance * ...
            measurementModel.' + measurementNoise;
        gain = (covariance * measurementModel.') / innovationCovariance;
        identity = eye(4);
        state = state + gain * innovation;
        covariance = (identity - gain * measurementModel) * covariance * ...
            (identity - gain * measurementModel).' + gain * measurementNoise * gain.';
        covariance = symmetrize(covariance);
        track.Tracker.MeasurementNoise = measurementNoise;
    end
    track.Tracker.State = state;
    track.Tracker.StateCovariance = covariance;
end

function tracker = localTracker(track, cfg)
    tracker = struct('Backend', 'localCV', 'State', track.CurrentState, ...
        'StateCovariance', track.CurrentCovariance, ...
        'MeasurementModel', [1 0 0 0; 0 1 0 0], ...
        'MeasurementNoise', cfg.minimumMeasurementVariance * eye(2), ...
        'ProcessNoise', track.ProcessNoise);
end

function cfg = trackingConfig(config)
    if isfield(config, 'tracking')
        cfg = config.tracking;
    else
        cfg = config;
    end
    required = {'minimumMeasurementVariance', 'measurementConfidenceWeight', ...
        'missedDetectionConfidenceDecay', 'confidenceCovarianceScale'};
    for index = 1:numel(required)
        if ~isfield(cfg, required{index})
            error('updateTracker:MissingConfiguration', ...
                'Missing tracking configuration field: %s.', required{index});
        end
    end
end

function covariance = measurementCovariance(detection, cfg)
    std = row2(readField(detection, {'PositionStd'}, [NaN NaN]));
    variance = std .^ 2;
    variance(~isfinite(variance)) = cfg.minimumMeasurementVariance;
    covariance = diag(max(variance, cfg.minimumMeasurementVariance));
end

function tf = validMeasurement(detection)
    tf = logical(readField(detection, {'IsDetected'}, false));
    position = row2(readField(detection, {'Position'}, [NaN NaN]));
    tf = tf && all(isfinite(position));
end

function matrix = transitionMatrix(dt)
    if ~isscalar(dt) || ~isfinite(dt) || dt <= 0
        error('updateTracker:InvalidTimeStep', 'dt must be positive.');
    end
    matrix = [1 0 dt 0; 0 1 0 dt; 0 0 1 0; 0 0 0 1];
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

function matrix = symmetrize(matrix)
    matrix = (matrix + matrix.') / 2;
end
