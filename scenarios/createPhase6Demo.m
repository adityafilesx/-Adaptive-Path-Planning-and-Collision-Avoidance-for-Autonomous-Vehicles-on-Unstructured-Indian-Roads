function demo = createPhase6Demo(config)
%CREATEPHASE6DEMO Deterministic scenario for ACARG Phase 6 testing.
%   Creates two actors whose baseline envelopes leave a direct route open,
%   while ACARG inflation produces a deterministic, more conservative route.
%
%   Actor 1: Stable car away from the direct route.
%   Actor 2: Low-confidence pedestrian near the route (CAUTIOUS response).

    if nargin < 1 || isempty(config)
        cfg = feval('config');
    else
        cfg = config;
    end
    
    cfg.tracking.preferTrackingKF = false;
    
    egoState = struct('Position', [0 0], 'Velocity', [10 0]);
    
    % Actor 1: stable car well to the side of the direct route.
    detection1 = struct('ID', 101, 'Position', [45 16 0], ...
        'Velocity', [8 0 0], 'PerceivedClass', 'car', 'TrueClass', 'car', ...
        'PositionStd', [0.2 0.2 0.1], 'VelocityStd', [0.1 0.1 0.1], ...
        'IsDetected', true, 'Confidence', 0.95);
    track1 = initializeTracker(detection1, cfg.sim.dt, cfg, 0);
    track1.CurrentCovariance = diag([0.04 0.04 0.01 0.01]);
    track1.ProcessNoise = 0.1;
    track1.DetectionCount = 10;
    track1.TrackingConfidence = 0.95;
    
    % Actor 2: uncertain, low-confidence pedestrian near the direct route.
    % Its baseline footprint permits a straight plan; ACARG inflation forces
    % additional clearance without covering either planning endpoint.
    detection2 = struct('ID', 102, 'Position', [34 7 0], ...
        'Velocity', [0 -0.2 0], 'PerceivedClass', 'pedestrian', 'TrueClass', 'pedestrian', ...
        'PositionStd', [0.8 0.8 0.1], 'VelocityStd', [0.5 0.5 0.1], ...
        'IsDetected', true, 'Confidence', 0.30);
    track2 = initializeTracker(detection2, cfg.sim.dt, cfg, 0);
    track2.CurrentCovariance = diag([0.64 0.64 0.25 0.25]);
    track2.ProcessNoise = 0.3;
    track2.DetectionCount = 4;
    track2.TrackingConfidence = 0.30;

    tracks = [track1; track2];
    
    % Get baseline map (pre-ACARG)
    riskMap = updateOccupancyMap(tracks, egoState, cfg);
    
    startPose = [0 0 0];
    goalPose = [70 0 0];
    
    demo = struct('config', cfg, 'egoState', egoState, 'tracks', tracks, ...
        'riskMap', riskMap, 'startPose', startPose, 'goalPose', goalPose);
end
