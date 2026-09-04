function scenario = createRapidRiskFluctuationScenario(cfg)
%CREATERAPIDRISKFLUCTUATIONSCENARIO Reversals exercise state hysteresis.

    actor = makePhase8Actor(830, 'pedestrian', [42 8], [0 -1.1], ...
        [0.6 0.6], 'Threshold pedestrian');
    scenario = makePhase9Scenario('Rapid Risk Fluctuation', 'risk-fluctuation', ...
        'A pedestrian reverses near risk thresholds to exercise governor hysteresis.', ...
        actor, [72 0 0], 25, 908, cfg);
    schedule(1) = struct('ActorID', 830, 'Time', 4.5, 'Velocity', [0 1.1]);
    schedule(2) = struct('ActorID', 830, 'Time', 6.5, 'Velocity', [0 -1.1]);
    schedule(3) = struct('ActorID', 830, 'Time', 8.5, 'Velocity', [0 1.1]);
    schedule(4) = struct('ActorID', 830, 'Time', 10.5, 'Velocity', [0 -1.1]);
    scenario.actorUpdateFcn = @(a,t) applyPhase9ActorSchedule(a, t, schedule);
    scenario.disturbanceWindow = [4.5 11];
    scenario.recoveryCriterion = 'goal';
end
