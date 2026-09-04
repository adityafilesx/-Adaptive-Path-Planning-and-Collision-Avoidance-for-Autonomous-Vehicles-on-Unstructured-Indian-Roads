function detections = addSensorNoise(groundTruth, egoState, config)
%ADDSENSORNOISE Apply the configured synthetic perception uncertainty.
%   DETECTIONS = ADDSENSORNOISE(GROUNDTRUTH, EGOSTATE, CONFIG) has the same
%   output as SIMULATEPERCEPTION. Supply the current ego state explicitly so
%   distance-dependent uncertainty uses the current ego position.
%
%   DETECTIONS = ADDSENSORNOISE(GROUNDTRUTH, CONFIG) is also supported for
%   simple use cases. CONFIG must then provide egoState, egoPosition, or the
%   full project's ego.initialPos configuration.

    if nargin == 2
        config = egoState;
        egoState = inferEgoState(config);
    elseif nargin ~= 3
        error('addSensorNoise:InvalidInput', ...
            'Use (groundTruth, egoState, config) or (groundTruth, config).');
    end

    detections = simulatePerception(groundTruth, egoState, config);
end

function egoState = inferEgoState(config)
    if isfield(config, 'egoState')
        egoState = config.egoState;
    elseif isfield(config, 'egoPosition')
        egoState = struct('Position', config.egoPosition);
    elseif isfield(config, 'ego') && isfield(config.ego, 'initialPos')
        egoState = struct('Position', config.ego.initialPos);
    else
        error('addSensorNoise:MissingEgoState', ...
            'The two-input form requires egoState, egoPosition, or ego.initialPos.');
    end
end
