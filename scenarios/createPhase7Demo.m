function demo = createPhase7Demo(config)
%CREATEPHASE7DEMO Deterministic crossing-pedestrian closed-loop scenario.

    if nargin < 1 || isempty(config)
        cfg = feval('config');
    else
        cfg = config;
    end
    cfg.tracking.preferTrackingKF = false;
    cfg.perception.positionNoiseStd = [0 0 0];
    cfg.perception.velocityNoiseStd = [0 0 0];
    cfg.perception.missedDetectionProbability = 0;
    cfg.perception.classificationConfusionProbability = 0;
    cfg.perception.distanceScalingFactor = 0;
    cfg.perception.randomSeed = [];
    cfg.governor.confidence.maturityThreshold = 1;
    cfg.tracking.classParameters.pedestrian.ProcessNoiseScale = 0.1;
    cfg.tracking.classParameters.pedestrian.InitialPositionVariance = 0.04;
    cfg.tracking.classParameters.pedestrian.InitialVelocityVariance = 0.04;

    egoState = struct('x', 0, 'y', 0, 'yaw', 0, 'speed', 0, ...
        'Position', [0 0 0], 'Velocity', [0 0 0]);
    goalPose = [70 0 0];
    pedestrian = struct('ID', 201, 'TrueClass', 'pedestrian', ...
        'ClassID', 4, 'Class', 'pedestrian', 'ActorClass', 'pedestrian', ...
        'Name', 'Crossing pedestrian', 'Position', [50 12 0], ...
        'Velocity', [0 -2 0], 'Yaw', -pi / 2, 'Orientation', [], ...
        'Dimensions', [0.6 0.6 1.7]);
    demo = struct('config', cfg, 'egoState', egoState, ...
        'goalPose', goalPose, 'actors', pedestrian, ...
        'description', ['A pedestrian crosses the route as the ego approaches, ' ...
        'causing risk-driven speed reduction and online replanning.']);
end
