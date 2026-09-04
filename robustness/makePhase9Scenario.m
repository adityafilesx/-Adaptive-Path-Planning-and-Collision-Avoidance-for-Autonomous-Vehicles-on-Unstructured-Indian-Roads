function scenario = makePhase9Scenario(name, disturbanceType, description, ...
        actors, goalPose, maxTime, seed, cfg)
%MAKEPHASE9SCENARIO Common deterministic Phase 9 scenario schema.

    ego = struct('x', 0, 'y', 0, 'yaw', 0, 'speed', 0, ...
        'Position', [0 0 0], 'Velocity', [0 0 0]);
    scenario = makePhase8Scenario(name, description, ego, goalPose, actors, ...
        maxTime, 'Traceable disturbance response and safe recovery', seed, cfg);
    scenario.disturbanceType = disturbanceType;
    scenario.disturbanceWindow = [NaN NaN];
    scenario.recoveryCriterion = 'goal';
    scenario.actorUpdateFcn = [];
    scenario.detectionModifierFcn = [];
    scenario.config.control.baseSpeed = 6.0;
    % Robustness cases must remain alive long enough to observe the clearing
    % phase after a deliberately temporary obstruction.
    scenario.config.control.maxConsecutivePlanningFailures = 100;
    scenario.config.occupancy.worldLimits(2, :) = [-70 70];
end
