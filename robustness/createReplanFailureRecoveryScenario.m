function scenario = createReplanFailureRecoveryScenario(cfg)
%CREATEREPLANFAILURERECOVERYSCENARIO A moving wall temporarily blocks the map.

    targetY = -24:6:24;
    actors = repmat(makePhase8Actor(810, 'bus', [50 20], [0 -5], ...
        [10.5 2.5], 'Moving barrier'), numel(targetY), 1);
    for i = 1:numel(targetY)
        actors(i) = makePhase8Actor(809 + i, 'bus', ...
            [50 targetY(i) + 40], [0 -5], [10.5 2.5], ...
            sprintf('Moving barrier %d', i));
    end
    scenario = makePhase9Scenario('Replan Failure Recovery', 'replan-failure', ...
        'A laterally moving vehicle wall first blocks distant planning, then the active path, and clears.', ...
        actors, [90 0 0], 32, 906, cfg);
    scenario.config.control.baseSpeed = 5.0;
    scenario.config.occupancy.worldLimits(2, :) = [-28 28];
    scenario.disturbanceWindow = [7 13];
    scenario.recoveryCriterion = 'planner-recovers';
end
