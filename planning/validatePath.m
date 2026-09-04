function validation = validatePath(pathData, plannerData, startPose, goalPose, config)
%VALIDATEPATH Check native plan geometry, map validity, and motion samples.

    cfg = config.planning;
    states = statesOf(pathData);
    validation = struct('isValid', false, 'message', '', ...
        'stateValidity', false(0, 1), 'motionValidity', false(0, 1), ...
        'metrics', struct('pathLength', 0, 'pathSmoothness', 0, ...
        'minimumClearance', 0));
    if size(states, 1) < 2
        validation.message = 'Path must contain at least two states.';
        return;
    end
    if size(states, 2) ~= 3 || any(~isfinite(states(:)))
        validation.message = 'Path contains invalid x, y, or theta values.';
        return;
    end
    xBounds = plannerData.ValidationMap.XWorldLimits;
    yBounds = plannerData.ValidationMap.YWorldLimits;
    if any(states(:, 1) < xBounds(1) | states(:, 1) > xBounds(2) | ...
            states(:, 2) < yBounds(1) | states(:, 2) > yBounds(2))
        validation.message = 'Path leaves occupancy-map world bounds.';
        return;
    end
    if any(abs(states(:, 3)) > pi + cfg.headingTolerance)
        validation.message = 'Path contains invalid heading values.';
        return;
    end
    if norm(states(1, 1:2) - startPose(1:2)) > cfg.startGoalTolerance || ...
            norm(states(end, 1:2) - goalPose(1:2)) > cfg.startGoalTolerance
        validation.message = 'Path endpoints are not near requested poses.';
        return;
    end
    jumpLengths = hypot(diff(states(:, 1)), diff(states(:, 2)));
    if any(jumpLengths > cfg.maxPathStateJump)
        validation.message = 'Path contains a pathological state jump.';
        return;
    end
    stateValidity = isStateValid(plannerData.Validator, states);
    if ~all(stateValidity)
        validation.stateValidity = stateValidity;
        validation.message = 'One or more path states collide with the inflated map.';
        return;
    end
    motionValidity = true(size(states, 1) - 1, 1);
    for index = 1:numel(motionValidity)
        motionValidity(index) = isMotionValid(plannerData.Validator, ...
            states(index, :), states(index + 1, :));
    end
    validation.stateValidity = stateValidity;
    validation.motionValidity = motionValidity;
    if ~all(motionValidity)
        validation.message = 'A path segment is invalid under validator sampling.';
        return;
    end
    validation.metrics = computePathMetrics(states, plannerData.ValidationMap, config);
    validation.isValid = true;
    validation.message = 'Path is valid.';
end

function states = statesOf(pathData)
    if isstruct(pathData) && isfield(pathData, 'states')
        states = pathData.states;
    else
        states = extractPathStates(pathData);
    end
end
