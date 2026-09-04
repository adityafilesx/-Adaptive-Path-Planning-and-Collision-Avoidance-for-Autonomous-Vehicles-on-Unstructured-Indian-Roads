function [reached, distanceError, yawError] = checkGoalReached(egoState, goalPose, cfg)
%CHECKGOALREACHED Evaluate configurable position and heading tolerances.

    distanceError = norm([egoState.x egoState.y] - goalPose(1:2));
    yawError = abs(wrapAngle(egoState.yaw - goalPose(3)));
    reached = distanceError <= cfg.control.goalTolerance && ...
        yawError <= cfg.control.goalYawTolerance;
end

function angle = wrapAngle(angle)
    angle = mod(angle + pi, 2 * pi) - pi;
end
