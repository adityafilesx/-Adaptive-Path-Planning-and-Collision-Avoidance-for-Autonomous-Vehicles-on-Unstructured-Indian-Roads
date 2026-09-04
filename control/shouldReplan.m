function [required, reasons, pathSafe] = shouldReplan(activePath, plannerData, ...
        currentPose, lastPlanTime, currentTime, acarg, previousACARG, cfg)
%SHOULDREPLAN Apply explicit safety-, risk-, state-, and time-based policy.

    reasons = cell(0, 1);
    hasPath = isstruct(activePath) && isfield(activePath, 'success') && ...
        activePath.success && isfield(activePath, 'states') && ...
        ~isempty(activePath.states);
    if hasPath
        pathSafe = isPathSafe(activePath, plannerData, currentPose, cfg);
    else
        pathSafe = false;
        reasons{end + 1, 1} = 'No active path.';
    end
    if hasPath && ~pathSafe
        reasons{end + 1, 1} = 'Upcoming active path is unsafe.';
    end

    sinceLastPlan = currentTime - lastPlanTime;
    cooldownElapsed = sinceLastPlan >= cfg.control.minimumReplanInterval;
    if cooldownElapsed && acarg.replanRequested
        reasons{end + 1, 1} = 'ACARG requested replanning.';
    end
    if cooldownElapsed && ~isempty(previousACARG) && ...
            ~strcmp(acarg.state, previousACARG.state)
        reasons{end + 1, 1} = 'Governor state changed.';
    end
    if cooldownElapsed && ~isempty(previousACARG) && ...
            abs(acarg.risk.totalRisk - previousACARG.risk.totalRisk) >= ...
            cfg.control.riskChangeThreshold
        reasons{end + 1, 1} = 'Risk changed significantly.';
    end
    if hasPath && sinceLastPlan >= cfg.control.replanInterval
        reasons{end + 1, 1} = 'Maximum replanning interval elapsed.';
    end
    required = ~isempty(reasons);
end
