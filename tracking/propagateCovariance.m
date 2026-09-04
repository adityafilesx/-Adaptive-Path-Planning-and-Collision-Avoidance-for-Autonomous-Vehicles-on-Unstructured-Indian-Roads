function covariance = propagateCovariance(covariance, dt, processNoise)
%PROPAGATECOVARIANCE Propagate a [x y vx vy] covariance one CV time step.
%   PROCESSNOISE is the configurable scalar acceleration-noise variance, or
%   a struct carrying ProcessNoise/processNoise/defaultProcessNoise.

    if ~isequal(size(covariance), [4 4]) || ~isfinite(dt) || dt <= 0
        error('propagateCovariance:InvalidInput', ...
            'Covariance must be 4-by-4 and dt must be positive.');
    end
    q = processNoiseValue(processNoise);
    transition = [1 0 dt 0; 0 1 0 dt; 0 0 1 0; 0 0 0 1];
    gain = [0.5 * dt^2 0; 0 0.5 * dt^2; dt 0; 0 dt];
    covariance = transition * covariance * transition.' + q * (gain * gain.');
    covariance = (covariance + covariance.') / 2;
end

function q = processNoiseValue(value)
    if isstruct(value)
        if isfield(value, 'ProcessNoise')
            value = value.ProcessNoise;
        elseif isfield(value, 'processNoise')
            value = value.processNoise;
        elseif isfield(value, 'defaultProcessNoise')
            value = value.defaultProcessNoise;
        else
            error('propagateCovariance:MissingProcessNoise', ...
                'No process-noise value was supplied.');
        end
    end
    if ~isscalar(value) || ~isfinite(value) || value < 0
        error('propagateCovariance:InvalidProcessNoise', ...
            'Process noise must be a finite, nonnegative scalar.');
    end
    q = value;
end
