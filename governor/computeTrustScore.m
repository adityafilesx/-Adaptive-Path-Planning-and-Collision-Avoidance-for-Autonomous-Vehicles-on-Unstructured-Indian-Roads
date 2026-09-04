function score = computeTrustScore(track, egoState, cfg)
%COMPUTETRUSTSCORE Weighted trust/confidence score for a tracked actor.
%   Combines four normalised signals from the Phase 3 track structure.
%   All signals are available from the existing track fields; no new
%   data is invented.
%
%   Signals:
%       1. TrackingConfidence — Phase 3 bounded confidence score
%       2. Covariance quality — inverse of position-covariance trace
%       3. Detection continuity — penalises consecutive missed detections
%       4. Track maturity — reward for sustained detection history
%
%   Output: score ∈ [0,1]   (higher = more trustworthy)

    gcfg = governorSubConfig(cfg, 'confidence');

    % Signal 1: Phase 3 tracking confidence (directly available)
    trackingConf = readField(track, {'TrackingConfidence'}, 0.5);
    trackingConf = bounded(trackingConf);

    % Signal 2: Covariance quality — low trace → high quality
    covariance = readField(track, {'CurrentCovariance'}, []);
    if isequal(size(covariance), [4 4]) && all(isfinite(covariance(:)))
        posTrace = trace(covariance(1:2, 1:2));
    else
        posTrace = gcfg.covarianceSaturation;
    end
    if ~isfinite(posTrace) || posTrace < 0
        posTrace = gcfg.covarianceSaturation;
    end
    covQuality = 1 / (1 + posTrace / gcfg.covarianceScale);

    % Signal 3: Detection continuity — consecutive misses degrade score
    missedCount = readField(track, {'MissedDetectionCount'}, 0);
    maxMissed   = readField(track, {'MaxMissedDetections'}, 12);
    gracePeriod = governorSubField(cfg, 'persistence', 'gracePeriod', 3);
    if missedCount <= gracePeriod
        continuity = max(0, 1 - missedCount / max(1, maxMissed));
    else
        decayRate = governorSubField(cfg, 'persistence', 'rapidDecayRate', 0.5);
        baseContinuity = max(0, 1 - gracePeriod / max(1, maxMissed));
        continuity = baseContinuity * decayRate ^ (missedCount - gracePeriod);
    end
    continuity = bounded(continuity);

    % Signal 4: Track maturity — more detections → higher maturity
    detectionCount = readField(track, {'DetectionCount'}, 1);
    maturity = min(1, detectionCount / max(1, gcfg.maturityThreshold));

    % Weighted combination
    score = gcfg.wTracking   * trackingConf + ...
            gcfg.wCovariance * covQuality   + ...
            gcfg.wContinuity * continuity   + ...
            gcfg.wMaturity   * maturity;
    score = bounded(score);
end

%% ---- local helpers ----

function gcfg = governorSubConfig(cfg, subField)
    if isfield(cfg, 'governor') && isfield(cfg.governor, subField)
        gcfg = cfg.governor.(subField);
    else
        error('computeTrustScore:MissingConfig', ...
            'cfg.governor.%s is required.', subField);
    end
end

function value = governorSubField(cfg, sub, field, fallback)
    if isfield(cfg, 'governor') && isfield(cfg.governor, sub) && ...
            isfield(cfg.governor.(sub), field)
        value = cfg.governor.(sub).(field);
    else
        value = fallback;
    end
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

function v = bounded(v)
    v = min(1, max(0, v));
end
