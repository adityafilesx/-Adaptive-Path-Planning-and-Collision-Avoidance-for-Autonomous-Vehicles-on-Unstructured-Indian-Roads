function testACARG()
%TESTACARG 18-test suite for Phase 6 Adaptive Confidence-Aware Risk Governor.

    clc;
    disp('============================================================');
    disp(' Running Phase 6 tests: Adaptive Confidence-Aware Risk Governor');
    disp('============================================================');

    cfg = config();
    cfg.governor.enabled = true;
    
    passed = 0;
    failed = 0;

    % Run tests
    try
        test1_ConfidenceWeights(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 1 FAILED: ' ME.message]); end
    
    try
        test2_UncertaintySaturation(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 2 FAILED: ' ME.message]); end
    
    try
        test3_ClassRiskWeights(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 3 FAILED: ' ME.message]); end
    
    try
        test4_CPAClosing(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 4 FAILED: ' ME.message]); end

    try
        test5_CPADiverging(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 5 FAILED: ' ME.message]); end
    
    try
        test6_DistanceRisk(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 6 FAILED: ' ME.message]); end
    
    try
        test7_TrajectoryRisk(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 7 FAILED: ' ME.message]); end
    
    try
        test8_ActorRiskCombination(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 8 FAILED: ' ME.message]); end
    
    try
        test9_GovernorHysteresis(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 9 FAILED: ' ME.message]); end
    
    try
        test10_ACARGEmpty(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 10 FAILED: ' ME.message]); end
    
    try
        test11_ACARGOrchestrator(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 11 FAILED: ' ME.message]); end
    
    try
        test12_AdaptiveEnvelopeScale(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 12 FAILED: ' ME.message]); end
    
    try
        test13_ReplanningUrgency(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 13 FAILED: ' ME.message]); end
    
    try
        test14_SpeedScale(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 14 FAILED: ' ME.message]); end
    
    try
        test15_MissedDetectionDecay(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 15 FAILED: ' ME.message]); end
    
    try
        test16_Fallback2DCPA(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 16 FAILED: ' ME.message]); end
    
    try
        test17_PerActorEnvelope(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 17 FAILED: ' ME.message]); end
    
    try
        test18_DemoScenarioCompletes(cfg); passed = passed + 1;
    catch ME, failed = failed + 1; disp(['TEST 18 FAILED: ' ME.message]); end
    
    fprintf('\nPhase 6 Tests Complete: %d passed, %d failed.\n', passed, failed);
    if failed > 0
        error('testACARG:Failures', 'One or more Phase 6 tests failed.');
    end
end

%% ---- TESTS ----

function test1_ConfidenceWeights(cfg)
    track = struct('TrackingConfidence', 1.0, 'CurrentCovariance', eye(4)*0, ...
        'MissedDetectionCount', 0, 'MaxMissedDetections', 10, 'DetectionCount', 10);
    score = computeTrustScore(track, [], cfg);
    assert(abs(score - 1.0) < 1e-4, 'Expected perfect trust for perfect signals.');
end

function test2_UncertaintySaturation(cfg)
    track = struct('CurrentCovariance', eye(4) * cfg.governor.uncertainty.varianceScale * 2);
    score = computeUncertaintyScore(track, cfg);
    assert(score == 1.0, 'Expected saturated uncertainty score.');
end

function test3_ClassRiskWeights(cfg)
    w_car = classRiskWeights('car', cfg);
    w_cattle = classRiskWeights('cattle', cfg);
    assert(w_car == 1.0, 'Car weight should be normalized to 1.0');
    assert(w_cattle > 1.0, 'Cattle weight should be > car weight');
end

function test4_CPAClosing(~)
    cpa = computeTTC([10 0], [-10 0], [0 0], [0 0]);
    assert(cpa.isClosing && cpa.tCPA == 1.0 && cpa.dCPA == 0, 'Expected collision in 1s');
end

function test5_CPADiverging(~)
    cpa = computeTTC([10 0], [10 0], [0 0], [0 0]);
    assert(~cpa.isClosing && cpa.tCPA == 0, 'Expected diverging CPA');
end

function test6_DistanceRisk(cfg)
    r1 = computeDistanceRisk([0 0], [0 0], cfg);
    r2 = computeDistanceRisk([100 0], [0 0], cfg);
    assert(r1 == 1.0, 'Risk at 0 dist should be 1');
    assert(r2 < 0.5, 'Risk at 100m should be low');
end

function test7_TrajectoryRisk(cfg)
    track = struct('CurrentState', [10; 0; -10; 0]);
    pred = struct('Position', [10 0; 0 0], 'Velocity', [-10 0; -10 0], 'Time', [0; 1]);
    egoState = struct('Position', [0 0], 'Velocity', [0 0]);
    risk = computeCollisionRisk(track, pred, egoState, [], cfg);
    assert(risk > 0.8, 'Expected high collision risk');
end

function test8_ActorRiskCombination(cfg)
    track = struct('ActorID', 1, 'CurrentState', [10; 0; -10; 0], 'CurrentCovariance', eye(4), ...
        'TrackingConfidence', 0.5, 'PerceivedClass', 'pedestrian', 'MissedDetectionCount', 0, 'MaxMissedDetections', 10, 'DetectionCount', 10);
    pred = struct('Position', [10 0; 0 0], 'Velocity', [-10 0; -10 0], 'Time', [0; 1]);
    egoState = struct('Position', [0 0], 'Velocity', [0 0]);
    ar = computeActorRisk(track, pred, egoState, [], cfg);
    assert(ar.risk > 0, 'Expected non-zero actor risk');
    assert(ar.safetyScale > 1.0, 'Expected safety scale > 1.0');
end

function test9_GovernorHysteresis(cfg)
    s1 = governorStateMachine(0.1, 'NORMAL', cfg);
    s2 = governorStateMachine(0.6, 'NORMAL', cfg); % cross cautiousEnter (0.35)
    s3 = governorStateMachine(0.3, 'CAUTIOUS', cfg); % not below cautiousExit (0.25)
    assert(strcmp(s1, 'NORMAL'), 'Should remain NORMAL');
    assert(strcmp(s2, 'CAUTIOUS'), 'Should enter CAUTIOUS');
    assert(strcmp(s3, 'CAUTIOUS'), 'Should remain CAUTIOUS due to hysteresis');
end

function test10_ACARGEmpty(cfg)
    acarg = acargGovernor([], struct('Position', [0 0], 'Velocity', [0 0]), cfg, []);
    assert(strcmp(acarg.state, 'NORMAL'), 'Empty scene should be NORMAL');
    assert(acarg.risk.totalRisk == 0, 'Empty scene should have 0 risk');
end

function test11_ACARGOrchestrator(cfg)
    track = struct('ActorID', 1, 'CurrentState', [10; 0; -10; 0], 'CurrentCovariance', eye(4), ...
        'TrackingConfidence', 0.5, 'PerceivedClass', 'pedestrian', 'MissedDetectionCount', 0, 'MaxMissedDetections', 10, 'DetectionCount', 10, 'ProcessNoise', 1.0);
    egoState = struct('Position', [0 0], 'Velocity', [0 0]);
    acarg = acargGovernor(track, egoState, cfg, []);
    assert(~isempty(acarg.risk.actorRisk), 'Should have actor risk');
end

function test12_AdaptiveEnvelopeScale(cfg)
    demo = createPhase6Demo(cfg);
    acarg = acargGovernor(demo.tracks, demo.egoState, demo.config, []);
    adaptiveRiskMap = applyAdaptiveSafetyEnvelope(demo.riskMap, acarg, demo.config);
    assert(adaptiveRiskMap.adaptiveEnvelopeApplied, 'Should flag envelope application');
end

function test13_ReplanningUrgency(cfg)
    track = struct('ActorID', 1, 'CurrentState', [10; 0; -10; 0], 'CurrentCovariance', eye(4), ...
        'TrackingConfidence', 0.5, 'PerceivedClass', 'pedestrian', 'MissedDetectionCount', 0, 'MaxMissedDetections', 10, 'DetectionCount', 10, 'ProcessNoise', 1.0);
    egoState = struct('Position', [0 0], 'Velocity', [0 0]);
    acarg = acargGovernor(track, egoState, cfg, []);
    assert(acarg.replanUrgency > 0, 'Should compute replan urgency');
end

function test14_SpeedScale(cfg)
    track = struct('ActorID', 1, 'CurrentState', [10; 0; -10; 0], ...
        'CurrentCovariance', eye(4), 'TrackingConfidence', 0.5, ...
        'PerceivedClass', 'pedestrian', 'MissedDetectionCount', 0, ...
        'MaxMissedDetections', 10, 'DetectionCount', 10, 'ProcessNoise', 1.0);
    egoState = struct('Position', [0 0], 'Velocity', [0 0]);
    expectedStates = {'NORMAL', 'CAUTIOUS', 'CONSERVATIVE_STOP'};

    for i = 1:numel(expectedStates)
        stateCfg = cfg;
        switch expectedStates{i}
            case 'NORMAL'
                stateCfg.governor.thresholds.cautiousEnter = inf;
                stateCfg.governor.thresholds.conservativeEnter = inf;
            case 'CAUTIOUS'
                stateCfg.governor.thresholds.cautiousEnter = 0;
                stateCfg.governor.thresholds.conservativeEnter = inf;
            case 'CONSERVATIVE_STOP'
                stateCfg.governor.thresholds.cautiousEnter = 0;
                stateCfg.governor.thresholds.conservativeEnter = 0;
        end

        acarg = acargGovernor(track, egoState, stateCfg, struct('state', 'NORMAL'));
        assert(strcmp(acarg.state, expectedStates{i}), ...
            'Governor did not enter the expected state');
        expectedSpeedScale = stateCfg.governor.speedScale.(acarg.state);
        assert(abs(acarg.speedScale - expectedSpeedScale) <= ...
            eps(max(1, abs(expectedSpeedScale))), ...
            'Speed scale should match the configured value for the final state');
    end
end

function test15_MissedDetectionDecay(cfg)
    track = struct('TrackingConfidence', 1.0, 'CurrentCovariance', eye(4)*0, ...
        'MissedDetectionCount', cfg.governor.persistence.gracePeriod + 2, 'MaxMissedDetections', 10, 'DetectionCount', 10);
    score = computeTrustScore(track, [], cfg);
    assert(score < 1.0, 'Score should decay after grace period');
end

function test16_Fallback2DCPA(cfg)
    track = struct('CurrentState', [10; 0; -10; 0]);
    egoState = struct('Position', [0 0], 'Velocity', [0 0]);
    risk = computeCollisionRisk(track, [], egoState, [], cfg); % empty prediction triggers fallback
    assert(risk > 0, 'Fallback CPA should return risk');
end

function test17_PerActorEnvelope(cfg)
    demo = createPhase6Demo(cfg);
    demo.tracks(1).PerceivedClass = 'car';
    demo.tracks(2).PerceivedClass = 'cattle';
    acarg = acargGovernor(demo.tracks, demo.egoState, demo.config, []);
    assert(isfield(acarg.risk.actorRisk, 'ActorID'), ...
        'Per-actor risk output should expose ActorID');
    outputActorIDs = [acarg.risk.actorRisk.ActorID];
    inputActorIDs = [demo.tracks.ActorID];
    assert(isequal(outputActorIDs, inputActorIDs), ...
        'Per-actor risk output should preserve track ActorID values');
    carAr = acarg.risk.actorRisk(outputActorIDs == demo.tracks(1).ActorID);
    cattleAr = acarg.risk.actorRisk(outputActorIDs == demo.tracks(2).ActorID);
    assert(isscalar(carAr) && isscalar(cattleAr), ...
        'Expected one per-actor risk output for each ActorID');
    assert(cattleAr.safetyScale > carAr.safetyScale, 'Cattle should have higher safety scale than car');
end

function test18_DemoScenarioCompletes(cfg)
    demo = createPhase6Demo(cfg);
    assert(~isempty(demo.tracks), 'Demo should generate tracks');
    assert(~isempty(demo.riskMap), 'Demo should generate riskMap');
end
