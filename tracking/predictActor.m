function prediction = predictActor(state, covariance, predictionHorizon, dt, config)
%PREDICTACTOR Propagate a constant-velocity actor state and covariance.
%   Returns the current estimate (time zero) and each future prediction step.

    if nargin < 5 || isempty(config)
        baseConfig = feval('config');
        config = baseConfig.tracking;
    end
    if nargin < 4 || isempty(dt)
        dt = readConfig(config, 'predictionStep');
    end
    if nargin < 3 || isempty(predictionHorizon)
        predictionHorizon = readConfig(config, 'predictionHorizon');
    end
    if ~isequal(size(state), [4 1]) || ~isequal(size(covariance), [4 4]) || ...
            ~isscalar(dt) || dt <= 0 || ~isscalar(predictionHorizon) || ...
            predictionHorizon < 0
        error('predictActor:InvalidInput', ...
            'Use a 4-by-1 state, 4-by-4 covariance, and valid time values.');
    end
    processNoise = processNoiseValue(config);
    times = 0:dt:predictionHorizon;
    if isempty(times) || times(end) < predictionHorizon
        times(end + 1) = predictionHorizon;
    end
    pointCount = numel(times);
    positions = zeros(pointCount, 2);
    velocities = zeros(pointCount, 2);
    covariances = zeros(4, 4, pointCount);
    positionCovariances = zeros(2, 2, pointCount);
    positionStd = zeros(pointCount, 2);
    currentState = state;
    currentCovariance = (covariance + covariance.') / 2;
    positions(1, :) = currentState(1:2).';
    velocities(1, :) = currentState(3:4).';
    covariances(:, :, 1) = currentCovariance;
    positionCovariances(:, :, 1) = currentCovariance(1:2, 1:2);
    positionStd(1, :) = sqrt(max(0, diag(positionCovariances(:, :, 1)))).';
    for index = 2:pointCount
        step = times(index) - times(index - 1);
        transition = [1 0 step 0; 0 1 0 step; 0 0 1 0; 0 0 0 1];
        currentState = transition * currentState;
        currentCovariance = propagateCovariance(currentCovariance, step, processNoise);
        positions(index, :) = currentState(1:2).';
        velocities(index, :) = currentState(3:4).';
        covariances(:, :, index) = currentCovariance;
        positionCovariances(:, :, index) = currentCovariance(1:2, 1:2);
        positionStd(index, :) = sqrt(max(0, diag(positionCovariances(:, :, index)))).';
    end
    prediction = struct('Time', times(:), 'Position', positions, ...
        'Velocity', velocities, 'Covariance', covariances, ...
        'PositionCovariance', positionCovariances, 'PositionStd', positionStd);
end

function value = readConfig(config, name)
    if isfield(config, 'tracking')
        config = config.tracking;
    end
    if isfield(config, name)
        value = config.(name);
    else
        error('predictActor:MissingConfiguration', ...
            'Missing tracking configuration field: %s.', name);
    end
end

function value = processNoiseValue(config)
    if isfield(config, 'tracking')
        config = config.tracking;
    end
    if isfield(config, 'ProcessNoise')
        value = config.ProcessNoise;
    elseif isfield(config, 'processNoise')
        value = config.processNoise;
    elseif isfield(config, 'defaultProcessNoise')
        value = config.defaultProcessNoise;
    else
        error('predictActor:MissingProcessNoise', ...
            'Configuration must supply process noise.');
    end
end
