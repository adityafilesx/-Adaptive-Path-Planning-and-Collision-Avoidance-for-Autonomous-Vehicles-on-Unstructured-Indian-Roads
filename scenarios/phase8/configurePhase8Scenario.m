function cfg = configurePhase8Scenario(cfg, maxSimulationTime, seed)
%CONFIGUREPHASE8SCENARIO Apply one common deterministic benchmark profile.

    cfg.tracking.preferTrackingKF = false;
    cfg.perception.positionNoiseStd = [0 0 0];
    cfg.perception.velocityNoiseStd = [0 0 0];
    cfg.perception.missedDetectionProbability = 0;
    cfg.perception.classificationConfusionProbability = 0;
    cfg.perception.distanceScalingFactor = 0;
    cfg.perception.randomSeed = [];
    cfg.governor.confidence.maturityThreshold = 1;
    classNames = fieldnames(cfg.tracking.classParameters);
    for i = 1:numel(classNames)
        name = classNames{i};
        cfg.tracking.classParameters.(name).ProcessNoiseScale = 0.1;
        cfg.tracking.classParameters.(name).InitialPositionVariance = 0.04;
        cfg.tracking.classParameters.(name).InitialVelocityVariance = 0.04;
    end
    cfg.control.maxSimulationTime = maxSimulationTime;
    cfg.control.randomSeed = seed;
    cfg.control.enableVisualization = false;
end
