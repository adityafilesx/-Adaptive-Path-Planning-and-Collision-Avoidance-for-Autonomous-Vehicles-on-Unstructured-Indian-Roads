function scenario = createTemporaryObstructionScenario(cfg)
%CREATETEMPORARYOBSTRUCTIONSCENARIO Moving bus invalidates the active route.

    actor = makePhase8Actor(806, 'bus', [60 20], [0 -2.0], ...
        [10.5 2.5], 'Crossing route obstruction');
    scenario = makePhase9Scenario('Temporary Path Obstruction', 'temporary-obstruction', ...
        'A long crossing vehicle temporarily invalidates the active route and then clears.', ...
        actor, [78 0 0], 25, 905, cfg);
    scenario.config.control.baseSpeed = 4.5;
    scenario.disturbanceWindow = [8 13];
    scenario.recoveryCriterion = 'path-restored';
end
