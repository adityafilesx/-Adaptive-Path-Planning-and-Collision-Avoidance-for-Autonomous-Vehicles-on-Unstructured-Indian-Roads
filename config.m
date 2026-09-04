% config.m
% Configuration settings for SIH26037 Autonomous Driving Simulation

function cfg = config()
    cfg = struct();
    
    % Simulation settings
    cfg.sim.dt = 0.1;           % Simulation step size (s)
    cfg.sim.stopTime = 10.0;    % Simulation stop time (s)
    
    % Ego vehicle settings
    cfg.ego.length = 4.7;
    cfg.ego.width = 1.8;
    cfg.ego.initialPos = [0, 0, 0];
    cfg.ego.initialSpeed = 10; % m/s
    
    % Target / Goal
    cfg.goal.pos = [100, 0, 0];
    
    % Obstacle settings (Phase 1)
    cfg.obs.length = 4.0;
    cfg.obs.width = 1.8;
    cfg.obs.initialPos = [30, 0.5, 0];
    cfg.obs.initialSpeed = 5; % m/s

    % ---------------------------------------------------------------------
    % Phase 2: Synthetic Sensor/Perception Layer with Controlled Uncertainty
    % These values model synthetic observations derived from scenario ground
    % truth.  They do not represent a real camera, LiDAR, or classifier.
    % ---------------------------------------------------------------------
    cfg.perception.positionNoiseStd = [0.25, 0.25, 0.05]; % m at near range
    cfg.perception.velocityNoiseStd = [0.15, 0.15, 0.05]; % m/s at near range
    cfg.perception.missedDetectionProbability = 0.05;     % [0, 1]
    cfg.perception.classificationConfusionProbability = 0.03; % [0, 1]
    cfg.perception.distanceUncertaintyStart = 20.0;       % m
    cfg.perception.distanceScalingFactor = 0.02;          % extra std per m
    cfg.perception.randomSeed = 37;                       % [] uses current RNG
    cfg.perception.minimumConfidence = 0.20;              % [0, 1]
    cfg.perception.maximumConfidence = 0.99;              % [0, 1]
    % Possible synthetic class labels for non-neural class confusion.
    cfg.perception.classLabels = [1, 2, 3, 4];

    % ---------------------------------------------------------------------
    % Phase 3: Class-conditioned constant-velocity tracking and prediction
    % These are simulation engineering parameters, not risk multipliers.
    % ---------------------------------------------------------------------
    cfg.tracking.enabled = true;
    cfg.tracking.model = 'constantVelocity';
    cfg.tracking.preferTrackingKF = true;
    cfg.tracking.predictionHorizon = 1.5;                 % s
    cfg.tracking.predictionStep = cfg.sim.dt;             % s
    cfg.tracking.defaultProcessNoise = 1.0;               % acceleration variance
    cfg.tracking.defaultPositionVariance = 1.0;           % m^2
    cfg.tracking.defaultVelocityVariance = 4.0;           % (m/s)^2
    cfg.tracking.minimumMeasurementVariance = 0.01;       % m^2
    cfg.tracking.maxMissedDetections = 12;
    cfg.tracking.maxPredictionWithoutDetection = 6;
    cfg.tracking.measurementConfidenceWeight = 0.65;
    cfg.tracking.missedDetectionConfidenceDecay = 0.85;
    cfg.tracking.confidenceCovarianceScale = 10.0;        % m^2

    cfg.tracking.classIDMap = struct('id1', 'car', 'id2', 'bus', ...
        'id3', 'truck', 'id4', 'motorcycle');
    cfg.tracking.classParameters = struct();
    cfg.tracking.classParameters.default = classTrackingParameters( ...
        1.0, cfg.tracking.defaultPositionVariance, ...
        cfg.tracking.defaultVelocityVariance, cfg.tracking.maxMissedDetections);
    cfg.tracking.classParameters.car = classTrackingParameters( ...
        0.8, 0.7, 2.0, 12);
    cfg.tracking.classParameters.bus = classTrackingParameters( ...
        0.8, 0.7, 2.0, 12);
    cfg.tracking.classParameters.truck = classTrackingParameters( ...
        0.8, 0.7, 2.0, 12);
    cfg.tracking.classParameters.auto = classTrackingParameters( ...
        1.0, 1.0, 3.0, 10);
    cfg.tracking.classParameters.motorcycle = classTrackingParameters( ...
        1.5, 1.5, 5.0, 8);
    cfg.tracking.classParameters.bicycle = classTrackingParameters( ...
        1.5, 1.5, 5.0, 8);
    cfg.tracking.classParameters.pedestrian = classTrackingParameters( ...
        2.0, 2.0, 6.0, 6);
    cfg.tracking.classParameters.pushcart = classTrackingParameters( ...
        2.0, 2.0, 6.0, 6);
    cfg.tracking.classParameters.animal = classTrackingParameters( ...
        2.0, 2.0, 6.0, 6);
    cfg.tracking.classParameters.cattle = classTrackingParameters( ...
        2.0, 2.0, 6.0, 6);

    % ---------------------------------------------------------------------
    % Phase 4: Dynamic occupancy and normalized risk representation
    % World convention is [x, y]: longitudinal x and lateral y, in meters.
    % Footprints and weights are tunable simulation engineering parameters.
    % ---------------------------------------------------------------------
    cfg.prediction.horizon = cfg.tracking.predictionHorizon;
    cfg.prediction.dt = cfg.tracking.predictionStep;

    cfg.occupancy.enabled = true;
    cfg.occupancy.cellSize = 0.25;                        % m/cell
    cfg.occupancy.resolution = 1 / cfg.occupancy.cellSize; % cells/m
    cfg.occupancy.worldLimits = [-10 120; -25 25];        % [xmin xmax; ymin ymax] m
    cfg.occupancy.uncertaintyKSigma = 2.0;
    cfg.occupancy.invalidCovarianceVariance = 16.0;       % m^2 safe fallback
    cfg.occupancy.minimumEllipseAxis = cfg.occupancy.cellSize / 2;
    cfg.occupancy.distanceDecayScale = 35.0;              % m
    cfg.occupancy.forwardRegionMultiplier = 1.20;
    cfg.occupancy.rearRegionMultiplier = 0.80;
    cfg.occupancy.minimumOccupancyRisk = 0.20;
    cfg.occupancy.uncertaintyVarianceScale = 16.0;        % m^2
    cfg.occupancy.timeRiskDecay = 0.10;                   % 1/s
    cfg.occupancy.classIDMap = cfg.tracking.classIDMap;
    cfg.occupancy.footprints = struct();
    cfg.occupancy.footprints.default = footprintParameters(4.0, 1.8, 0.6, 0.50);
    cfg.occupancy.footprints.car = footprintParameters(4.7, 1.8, 0.5, 0.50);
    cfg.occupancy.footprints.bus = footprintParameters(10.5, 2.5, 0.8, 0.65);
    cfg.occupancy.footprints.truck = footprintParameters(9.0, 2.5, 0.8, 0.65);
    cfg.occupancy.footprints.auto = footprintParameters(3.2, 1.5, 0.7, 0.65);
    cfg.occupancy.footprints.motorcycle = footprintParameters(2.2, 0.8, 0.8, 0.65);
    cfg.occupancy.footprints.two_wheeler = footprintParameters(2.2, 0.8, 0.8, 0.65);
    cfg.occupancy.footprints.bicycle = footprintParameters(1.8, 0.6, 0.8, 0.60);
    cfg.occupancy.footprints.pedestrian = footprintParameters(0.6, 0.6, 1.0, 0.90);
    cfg.occupancy.footprints.pushcart = footprintParameters(2.0, 1.0, 1.0, 0.80);
    cfg.occupancy.footprints.animal = footprintParameters(2.4, 1.0, 1.25, 0.95);
    cfg.occupancy.footprints.cattle = footprintParameters(2.4, 1.0, 1.25, 0.95);

    % ---------------------------------------------------------------------
    % Phase 5: Vehicle-aware Hybrid A* baseline planner
    % Vehicle dimensions are generic passenger-vehicle simulation parameters.
    % ---------------------------------------------------------------------
    cfg.vehicle.length = 4.7;
    cfg.vehicle.width = 1.8;
    cfg.vehicle.wheelbase = 2.8;
    cfg.vehicle.minTurningRadius = 5.0;
    cfg.vehicle.validationSafetyMargin = 0.30;

    cfg.planning.enabled = true;
    cfg.planning.minTurningRadius = cfg.vehicle.minTurningRadius;
    cfg.planning.motionPrimitiveLength = 1.0;
    cfg.planning.numMotionPrimitives = 5;
    cfg.planning.motionDirection = "forward";
    cfg.planning.forwardCost = 1.0;
    cfg.planning.reverseCost = 3.0;
    cfg.planning.directionSwitchingCost = 5.0;
    cfg.planning.analyticExpansionInterval = 10;
    cfg.planning.interpolationDistance = 0.25;
    cfg.planning.maxNumNodes = 5000;
    cfg.planning.maxNumPathStates = 5000;
    cfg.planning.validationDistance = 0.25;
    cfg.planning.startGoalTolerance = 1.5;
    cfg.planning.headingTolerance = pi / 3;
    cfg.planning.maxPathStateJump = 2.0;
    cfg.planning.replanClearance = 1.0;
    cfg.planning.replanInterval = 1.0;
    cfg.planning.goalChangeTolerance = 0.5;
    cfg.planning.maximumReportedClearance = 50.0;

    cfg.visualization.showPlanner = true;
    cfg.visualization.showVehicleFootprint = true;
    cfg.visualization.showHeading = true;
    cfg.visualization.vehicleFootprintStride = 8;

    % ---------------------------------------------------------------------
    % Phase 6: Adaptive Confidence-Aware Risk Governor (ACARG)
    % ACARG is a system-level confidence-aware risk governance layer for
    % adaptive safety behavior in heterogeneous and uncertain mixed-traffic
    % environments.  These are initial engineering parameters, NOT values
    % learned from IDD or calibrated from experimental data.
    % ---------------------------------------------------------------------
    cfg.governor.enabled = false;                          % false = Phase 5 baseline

    % Confidence estimation weights (should sum to approximately 1.0)
    cfg.governor.confidence.wTracking   = 0.35;            % Phase 3 TrackingConfidence
    cfg.governor.confidence.wCovariance = 0.25;            % covariance quality
    cfg.governor.confidence.wContinuity = 0.25;            % detection continuity
    cfg.governor.confidence.wMaturity   = 0.15;            % track age / detection count
    cfg.governor.confidence.covarianceScale = 10.0;        % m^2 — half-confidence point
    cfg.governor.confidence.covarianceSaturation = 100.0;  % m^2 — maximum expected trace
    cfg.governor.confidence.maturityThreshold = 5;         % detections to reach full maturity

    % Uncertainty estimation
    cfg.governor.uncertainty.varianceScale = 16.0;         % m^2 — U=1 saturation point

    % Risk component weights (should sum to approximately 1.0)
    cfg.governor.risk.wUncertainty = 0.25;                 % uncertainty contribution
    cfg.governor.risk.wConfidence  = 0.25;                 % inverse-confidence contribution
    cfg.governor.risk.wDistance    = 0.20;                  % proximity contribution
    cfg.governor.risk.wCollision   = 0.30;                 % collision / CPA contribution
    cfg.governor.risk.distanceDecayScale = 30.0;           % m — exponential distance decay
    cfg.governor.risk.ttcScale = 3.0;                      % s — TTC half-risk point
    cfg.governor.risk.cpaSafeDistance = 5.0;                % m — CPA distance for risk=0.5
    cfg.governor.risk.maxPredictionSteps = 15;             % max trajectory steps to evaluate

    % Class-dependent risk weights (engineering priors, NOT IDD-derived)
    % Normalised internally relative to car baseline in classRiskWeights.m.
    cfg.governor.classWeights.car         = 0.80;
    cfg.governor.classWeights.bus         = 0.90;
    cfg.governor.classWeights.truck       = 0.90;
    cfg.governor.classWeights.auto        = 1.00;
    cfg.governor.classWeights.motorcycle  = 1.10;
    cfg.governor.classWeights.two_wheeler = 1.10;
    cfg.governor.classWeights.bicycle     = 1.10;
    cfg.governor.classWeights.pedestrian  = 1.20;
    cfg.governor.classWeights.pushcart    = 1.20;
    cfg.governor.classWeights.animal      = 1.30;
    cfg.governor.classWeights.cattle      = 1.30;
    cfg.governor.classWeights.unknown     = 1.30;
    cfg.governor.classWeights.default     = 1.00;

    % Governor state hysteresis thresholds
    cfg.governor.thresholds.cautiousEnter     = 0.35;
    cfg.governor.thresholds.cautiousExit      = 0.25;
    cfg.governor.thresholds.conservativeEnter = 0.70;
    cfg.governor.thresholds.conservativeExit  = 0.55;

    % Adaptive safety envelope — per-actor scaling
    cfg.governor.safetyEnvelope.riskScaling = 1.5;         % max additional scale from risk
    cfg.governor.safetyEnvelope.stateScale.NORMAL             = 1.0;
    cfg.governor.safetyEnvelope.stateScale.CAUTIOUS           = 1.2;
    cfg.governor.safetyEnvelope.stateScale.CONSERVATIVE_STOP  = 1.5;

    % Speed scale per governor state
    cfg.governor.speedScale.NORMAL             = 1.0;
    cfg.governor.speedScale.CAUTIOUS           = 0.65;
    cfg.governor.speedScale.CONSERVATIVE_STOP  = 0.25;

    % Replanning urgency
    cfg.governor.replan.urgencyThreshold       = 0.50;     % replan when urgency > this
    cfg.governor.replan.riskUrgencyWeight       = 0.60;
    cfg.governor.replan.confidenceUrgencyWeight = 0.40;

    % Missed-detection persistence / confidence degradation
    cfg.governor.persistence.gracePeriod    = 3;           % misses before rapid decay
    cfg.governor.persistence.rapidDecayRate = 0.50;        % multiplier per miss after grace

    % ---------------------------------------------------------------------
    % Phase 7: deterministic closed-loop ego control and online replanning
    % ---------------------------------------------------------------------
    cfg.control.dt = 0.20;                                 % s
    cfg.control.baseSpeed = 6.0;                           % m/s
    cfg.control.lookaheadDistance = 4.0;                   % m
    cfg.control.maxSteering = pi / 6;                      % rad
    cfg.control.maxAcceleration = 2.0;                     % m/s^2
    cfg.control.maxDeceleration = 4.0;                     % m/s^2
    cfg.control.speedControlGain = 1.5;
    cfg.control.goalTolerance = 1.0;                       % m
    cfg.control.goalYawTolerance = pi;                     % rad
    cfg.control.maxSimulationTime = 20.0;                  % s
    cfg.control.replanInterval = 3.0;                      % s
    cfg.control.minimumReplanInterval = 0.8;               % s
    cfg.control.riskChangeThreshold = 0.12;
    cfg.control.pathSafetyHorizon = 18.0;                  % m ahead
    cfg.control.collisionBuffer = 0.0;                     % m
    cfg.control.maxConsecutivePlanningFailures = 5;
    cfg.control.pathChangeTolerance = 0.10;                % m
    cfg.control.enableVisualization = true;
    cfg.control.randomSeed = 73;

    % ---------------------------------------------------------------------
    % Phase 10: optional RoadRunner integration boundary
    % RoadRunner is a scene/state adapter only.  The validated MATLAB
    % bicycle model remains authoritative unless a later phase says otherwise.
    % A machine-specific root can instead be supplied through the
    % SIH_ROADRUNNER_PROJECT_ROOT environment variable or
    % roadrunnerLocalConfig.m (see roadrunner/README.md).
    % ---------------------------------------------------------------------
    cfg.roadrunner.enabled = false;
    cfg.roadrunner.projectRoot = '';
    cfg.roadrunner.sceneDirectory = 'Scenes';
    cfg.roadrunner.scenarioDirectory = 'Scenarios';
    cfg.roadrunner.assetDirectory = 'Assets';
    cfg.roadrunner.runtimeValidationRequired = false;
    cfg.roadrunner.bridgeMode = 'MATLAB_AUTHORITATIVE';
    cfg.roadrunner.controlStep = cfg.control.dt;
    cfg.roadrunner.maxTimeDrift = 0.05;
    cfg.roadrunner.coordinateTransform = struct( ...
        'positionRotation', eye(3), 'translation', [0 0 0]);
end

function parameters = classTrackingParameters(processNoiseScale, ...
        initialPositionVariance, initialVelocityVariance, maxMissedDetections)
    parameters = struct('ProcessNoiseScale', processNoiseScale, ...
        'InitialPositionVariance', initialPositionVariance, ...
        'InitialVelocityVariance', initialVelocityVariance, ...
        'MaxMissedDetections', maxMissedDetections);
end

function parameters = footprintParameters(length, width, safetyMargin, riskWeight)
    parameters = struct('Length', length, 'Width', width, ...
        'SafetyMargin', safetyMargin, 'RiskWeight', riskWeight);
end
