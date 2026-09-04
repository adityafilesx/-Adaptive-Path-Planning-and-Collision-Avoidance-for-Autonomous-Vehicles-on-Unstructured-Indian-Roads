function [nextState, applied] = kinematicBicycleStep(state, steering, acceleration, cfg)
%KINEMATICBICYCLESTEP Advance [x,y,yaw,speed] with bounded SI-unit inputs.

    validateState(state);
    control = controlConfig(cfg);
    dt = control.dt;
    wheelbase = cfg.vehicle.wheelbase;
    steering = clamp(steering, -control.maxSteering, control.maxSteering);
    acceleration = clamp(acceleration, -control.maxDeceleration, ...
        control.maxAcceleration);

    nextSpeed = max(0, state.speed + acceleration * dt);
    averageSpeed = 0.5 * (state.speed + nextSpeed);
    yawRate = averageSpeed / wheelbase * tan(steering);
    middleYaw = state.yaw + 0.5 * yawRate * dt;

    nextState = state;
    nextState.x = state.x + averageSpeed * cos(middleYaw) * dt;
    nextState.y = state.y + averageSpeed * sin(middleYaw) * dt;
    nextState.yaw = wrapAngle(state.yaw + yawRate * dt);
    nextState.speed = nextSpeed;
    nextState = synchronizeState(nextState);
    applied = struct('steering', steering, 'acceleration', acceleration, ...
        'yawRate', yawRate);
end

function validateState(state)
    required = {'x', 'y', 'yaw', 'speed'};
    for i = 1:numel(required)
        if ~isstruct(state) || ~isfield(state, required{i}) || ...
                ~isscalar(state.(required{i})) || ~isfinite(state.(required{i}))
            error('kinematicBicycleStep:InvalidState', ...
                'State requires finite scalar x, y, yaw, and speed fields.');
        end
    end
end

function control = controlConfig(cfg)
    if ~isfield(cfg, 'control') || ~isfield(cfg, 'vehicle') || ...
            ~isfield(cfg.vehicle, 'wheelbase') || cfg.vehicle.wheelbase <= 0
        error('kinematicBicycleStep:MissingConfig', ...
            'cfg.control and a positive cfg.vehicle.wheelbase are required.');
    end
    control = cfg.control;
end

function state = synchronizeState(state)
    state.Position = [state.x state.y 0];
    state.Velocity = [state.speed * cos(state.yaw), ...
        state.speed * sin(state.yaw), 0];
end

function value = clamp(value, lower, upper)
    value = min(upper, max(lower, value));
end

function angle = wrapAngle(angle)
    angle = mod(angle + pi, 2 * pi) - pi;
end
