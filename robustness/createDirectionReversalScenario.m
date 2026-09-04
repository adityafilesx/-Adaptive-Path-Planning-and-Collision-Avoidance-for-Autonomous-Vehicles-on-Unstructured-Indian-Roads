function scenario = createDirectionReversalScenario(cfg)
%CREATEDIRECTIONREVERSALSCENARIO Reverse a pedestrian without teleportation.

    actor = makePhase8Actor(803, 'pedestrian', [45 8], [0 0.8], ...
        [0.6 0.6], 'Reversing pedestrian');
    scenario = makePhase9Scenario('Sudden Direction Reversal', 'direction-reversal', ...
        'A pedestrian initially moves away, reverses, and crosses toward the ego corridor.', ...
        actor, [75 0 0], 24, 903, cfg);
    schedule = struct('ActorID', 803, 'Time', 4, 'Velocity', [0 -3.0]);
    scenario.actorUpdateFcn = @(a,t) applyPhase9ActorSchedule(a, t, schedule);
    scenario.disturbanceWindow = [4 12];
    scenario.recoveryCriterion = 'post-disturbance-motion';
end
