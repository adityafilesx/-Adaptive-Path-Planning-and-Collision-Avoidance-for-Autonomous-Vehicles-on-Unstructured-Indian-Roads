function pathData = planPath(plannerData, startPose, goalPose, config)
%PLANPATH Find and package a Hybrid A* path without fabricating fallbacks.

    cfg = config;
    pathData = emptyPath(startPose, goalPose);
    if ~validPose(startPose) || ~validPose(goalPose)
        pathData.failureReason = 'Start and goal must be finite [x y theta] poses.';
        return;
    end
    if ~isStateValid(plannerData.Validator, startPose)
        pathData.failureReason = 'Start pose is invalid in the vehicle-inflated map.';
        return;
    end
    if ~isStateValid(plannerData.Validator, goalPose)
        pathData.failureReason = 'Goal pose is invalid in the vehicle-inflated map.';
        return;
    end
    try
        [nativePath, solutionInfo] = plan(plannerData.Planner, startPose, goalPose);
    catch firstError
        try
            nativePath = plan(plannerData.Planner, startPose, goalPose);
            solutionInfo = struct();
        catch secondError
            pathData.failureReason = secondError.message;
            pathData.plannerError = firstError.message;
            return;
        end
    end
    try
        states = extractPathStates(nativePath);
    catch errorInfo
        pathData.failureReason = errorInfo.message;
        return;
    end
    pathData.navPath = nativePath;
    pathData.solutionInfo = solutionInfo;
    pathData.states = states;
    if isempty(states)
        pathData.failureReason = 'Planner returned no path states.';
        return;
    end
    validation = validatePath(pathData, plannerData, startPose, goalPose, cfg);
    pathData.validation = validation;
    pathData.metrics = validation.metrics;
    pathData.x = states(:, 1);
    pathData.y = states(:, 2);
    pathData.theta = states(:, 3);
    pathData.length = validation.metrics.pathLength;
    pathData.success = validation.isValid;
    if ~validation.isValid
        pathData.failureReason = validation.message;
    end
end

function pathData = emptyPath(startPose, goalPose)
    pathData = struct('success', false, 'failureReason', '', 'plannerError', '', ...
        'startPose', startPose, 'goalPose', goalPose, 'navPath', [], ...
        'solutionInfo', struct(), 'states', zeros(0, 3), 'x', zeros(0, 1), ...
        'y', zeros(0, 1), 'theta', zeros(0, 1), 'length', 0, 'metrics', struct());
end

function tf = validPose(pose)
    tf = isnumeric(pose) && numel(pose) == 3 && all(isfinite(pose(:)));
end
