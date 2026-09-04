function [steering, info] = followPath(egoState, pathData, cfg)
%FOLLOWPATH Compute a bounded pure-pursuit steering command.

    steering = 0;
    info = struct('nearestIndex', 0, 'targetIndex', 0, ...
        'targetPoint', [NaN NaN], 'headingError', 0);
    if ~isstruct(pathData) || ~isfield(pathData, 'success') || ...
            ~pathData.success || ~isfield(pathData, 'states') || ...
            isempty(pathData.states)
        return;
    end

    states = pathData.states;
    position = [egoState.x egoState.y];
    distances = hypot(states(:, 1) - position(1), states(:, 2) - position(2));
    [~, nearestIndex] = min(distances);
    targetIndex = nearestIndex;
    travelled = 0;
    while targetIndex < size(states, 1) && ...
            travelled < cfg.control.lookaheadDistance
        targetIndex = targetIndex + 1;
        travelled = travelled + norm(states(targetIndex, 1:2) - ...
            states(targetIndex - 1, 1:2));
    end
    target = states(targetIndex, 1:2);
    targetBearing = atan2(target(2) - egoState.y, target(1) - egoState.x);
    headingError = wrapAngle(targetBearing - egoState.yaw);
    distanceToTarget = max(cfg.control.lookaheadDistance, ...
        norm(target - position));
    steering = atan2(2 * cfg.vehicle.wheelbase * sin(headingError), ...
        distanceToTarget);
    steering = min(cfg.control.maxSteering, ...
        max(-cfg.control.maxSteering, steering));
    info = struct('nearestIndex', nearestIndex, 'targetIndex', targetIndex, ...
        'targetPoint', target, 'headingError', headingError);
end

function angle = wrapAngle(angle)
    angle = mod(angle + pi, 2 * pi) - pi;
end
