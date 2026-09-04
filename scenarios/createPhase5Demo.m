function demo = createPhase5Demo(config)
%CREATEPHASE5DEMO Standalone deterministic occupancy-to-plan demonstration.
%   It uses Phase 3/4 structs and never calls drivingScenario or RoadRunner.

    if nargin < 1 || isempty(config)
        cfg = feval('config');
    else
        cfg = config;
    end
    cfg.tracking.preferTrackingKF = false;
    egoState = struct('Position', [0 0], 'Velocity', [8 0]);
    blocker = makeBlocker(cfg);
    tracks = blocker;
    riskMap = updateOccupancyMap(tracks, egoState, cfg);
    plannerData = createPlanner(riskMap, cfg);
    startPose = [0 0 0];
    goalPose = [55 0 0];
    demo = struct('config', cfg, 'egoState', egoState, 'tracks', tracks, ...
        'riskMap', riskMap, 'plannerData', plannerData, ...
        'startPose', startPose, 'goalPose', goalPose);
end

function track = makeBlocker(cfg)
    detection = struct('ID', 205, 'Position', [25 0 0], ...
        'Velocity', [0 0 0], 'PerceivedClass', 'truck', 'TrueClass', 'truck', ...
        'PositionStd', [0.25 0.25 0.1], 'VelocityStd', [0.2 0.2 0.1], ...
        'IsDetected', true, 'Confidence', 0.95);
    track = initializeTracker(detection, cfg.sim.dt, cfg, 0);
end
