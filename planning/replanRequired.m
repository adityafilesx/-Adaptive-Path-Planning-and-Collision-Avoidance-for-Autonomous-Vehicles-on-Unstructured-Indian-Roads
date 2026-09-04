function [required, reasons] = replanRequired(pathData, plannerData, ...
        currentPose, goalPose, lastPlanTime, currentTime, config)
%REPLANREQUIRED Report basic baseline replanning triggers without risk policy.

    cfg = config.planning;
    reasons = cell(0, 1);
    if ~isfield(pathData, 'success') || ~pathData.success || isempty(pathData.states)
        reasons{end + 1, 1} = 'No valid current path.'; %#ok<AGROW>
    else
        existingGoal = pathData.goalPose;
        if norm(existingGoal(1:2) - goalPose(1:2)) > cfg.goalChangeTolerance || ...
                abs(wrapAngle(existingGoal(3) - goalPose(3))) > cfg.headingTolerance
            reasons{end + 1, 1} = 'Goal pose changed.'; %#ok<AGROW>
        end
        validation = validatePath(pathData, plannerData, pathData.startPose, ...
            pathData.goalPose, config);
        if ~validation.isValid
            reasons{end + 1, 1} = 'Current path is blocked or invalid.'; %#ok<AGROW>
        elseif validation.metrics.minimumClearance < cfg.replanClearance
            reasons{end + 1, 1} = 'Minimum clearance is below threshold.'; %#ok<AGROW>
        end
    end
    if currentTime - lastPlanTime >= cfg.replanInterval
        reasons{end + 1, 1} = 'Replanning interval reached.'; %#ok<AGROW>
    end
    if nargin >= 3 && ~isempty(currentPose) && ...
            ~isStateValid(plannerData.Validator, currentPose)
        reasons{end + 1, 1} = 'Current pose is invalid.'; %#ok<AGROW>
    end
    required = ~isempty(reasons);
end

function angle = wrapAngle(angle)
    angle = mod(angle + pi, 2 * pi) - pi;
end
