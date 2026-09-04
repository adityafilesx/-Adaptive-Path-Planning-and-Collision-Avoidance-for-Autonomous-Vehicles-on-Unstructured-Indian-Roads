function [safe, details] = isPathSafe(pathData, plannerData, currentPose, cfg)
%ISPATHSAFE Validate the upcoming active-path segment against the latest map.

    details = struct('nearestIndex', 0, 'lastCheckedIndex', 0, ...
        'stateValidity', false(0, 1), 'motionValidity', false(0, 1));
    safe = false;
    if isempty(plannerData) || ~isstruct(pathData) || ...
            ~isfield(pathData, 'success') || ~pathData.success || ...
            ~isfield(pathData, 'states') || size(pathData.states, 1) < 2
        return;
    end
    states = pathData.states;
    distances = hypot(states(:, 1) - currentPose(1), ...
        states(:, 2) - currentPose(2));
    [~, firstIndex] = min(distances);
    lastIndex = firstIndex;
    distanceAhead = 0;
    while lastIndex < size(states, 1) && ...
            distanceAhead < cfg.control.pathSafetyHorizon
        lastIndex = lastIndex + 1;
        distanceAhead = distanceAhead + norm(states(lastIndex, 1:2) - ...
            states(lastIndex - 1, 1:2));
    end
    upcoming = [currentPose; states(firstIndex:lastIndex, :)];
    stateValidity = isStateValid(plannerData.Validator, upcoming);
    motionValidity = true(size(upcoming, 1) - 1, 1);
    for i = 1:numel(motionValidity)
        motionValidity(i) = isMotionValid(plannerData.Validator, ...
            upcoming(i, :), upcoming(i + 1, :));
    end
    safe = all(stateValidity) && all(motionValidity);
    details = struct('nearestIndex', firstIndex, ...
        'lastCheckedIndex', lastIndex, 'stateValidity', stateValidity, ...
        'motionValidity', motionValidity);
end
