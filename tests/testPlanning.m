% testPlanning.m
% Deterministic Phase 5 tests using only Phase 4 map output and Navigation Toolbox.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
cfg = config();
cfg.tracking.preferTrackingKF = false;
egoState = struct('Position', [0 0], 'Velocity', [0 0]);

% TEST 1/2 — planner and validator initialize from a Phase 4 empty map.
emptyRiskMap = updateOccupancyMap(struct([]), egoState, cfg);
emptyPlanner = createPlanner(emptyRiskMap, cfg);
assert(isa(emptyPlanner.Planner, 'plannerHybridAStar'), 'Planner did not initialize.');
assert(isa(emptyPlanner.Validator, 'validatorOccupancyMap'), 'Validator did not initialize.');

startPose = [0 0 0];
goalPose = [40 0 0];

% TEST 3/4 — valid endpoints and an obstacle-free plan.
assert(isStateValid(emptyPlanner.Validator, startPose) && ...
    isStateValid(emptyPlanner.Validator, goalPose), ...
    'Configured free-map start/goal must be valid.');
freePath = planPath(emptyPlanner, startPose, goalPose, cfg);
assert(freePath.success, 'Planner must solve the obstacle-free map.');

% TEST 5 — route around a deterministic Phase 4 generated obstacle.
blocker = makeTrack(401, 'truck', [20 0], [0 0], cfg);
blockedCfg = cfg;
blockedCfg.prediction.horizon = 0;
blockedRiskMap = updateOccupancyMap(blocker, egoState, blockedCfg);
blockedPlanner = createPlanner(blockedRiskMap, blockedCfg);
blockedPath = planPath(blockedPlanner, startPose, goalPose, blockedCfg);
assert(blockedPath.success, 'Planner must route around the deterministic obstacle.');
% Detour verification: the path must actually leave the Y=0 centreline.
maxLateralDeviation = max(abs(blockedPath.y));
assert(maxLateralDeviation > 0.5, ...
    'Detour path must deflect laterally to avoid the obstacle.');

% TEST 6–11 — path representation, endpoint, validity, and metrics.
assert(all(isfinite(blockedPath.states(:))), 'Path states must be finite.');
assert(norm(blockedPath.states(1, 1:2) - startPose(1:2)) <= ...
    cfg.planning.startGoalTolerance, 'Path start is incorrect.');
assert(norm(blockedPath.states(end, 1:2) - goalPose(1:2)) <= ...
    cfg.planning.startGoalTolerance, 'Path goal is incorrect.');
assert(all(blockedPath.validation.stateValidity) && ...
    all(blockedPath.validation.motionValidity), 'Validator rejected planned path.');
assert(blockedPath.metrics.pathLength > 0, 'Path length must be positive.');
assert(isfinite(blockedPath.metrics.minimumClearance) && ...
    blockedPath.metrics.minimumClearance >= 0, 'Minimum clearance is invalid.');

% TEST 12 — invalid start/goal yields a clean failure.
invalidPath = planPath(emptyPlanner, [NaN 0 0], goalPose, cfg);
assert(~invalidPath.success && ~isempty(invalidPath.failureReason), ...
    'Invalid start pose must fail cleanly.');

% TEST 13 — a Phase 4 wall produces a clean no-path result.
wallCfg = cfg;
wallCfg.occupancy.footprints.cattle.Width = ...
    diff(wallCfg.occupancy.worldLimits(2, :));
wall = makeTrack(402, 'cattle', [20 0], [0 0], wallCfg);
wallRiskMap = updateOccupancyMap(wall, egoState, wallCfg);
wallPlanner = createPlanner(wallRiskMap, wallCfg);
wallPath = planPath(wallPlanner, startPose, goalPose, wallCfg);
assert(~wallPath.success && ~isempty(wallPath.failureReason), ...
    'No-path map must return a clean failure.');

% TEST 14 — replan trigger detects that a formerly free path is now blocked.
[required, reasons] = replanRequired(freePath, blockedPlanner, startPose, ...
    goalPose, 0, 0, cfg);
assert(required && ~isempty(reasons), 'Newly blocked path must require replanning.');

% TEST 15 — invalid occupancy input is handled safely.
failedCleanly = false;
try
    createPlanner(struct(), cfg);
catch errorInfo
    failedCleanly = strcmp(errorInfo.identifier, 'createPlanner:InvalidOccupancyInput');
end
assert(failedCleanly, 'Invalid occupancy input must produce a clear error.');

% TEST 16 — clearance Y-coordinate regression guard.
% Place an obstacle at a known world Y, compute clearance for a path that
% passes at a known offset, and verify the clearance matches the offset.
regressionCfg = cfg;
regressionCfg.prediction.horizon = 0;
regressionObstacle = makeTrack(403, 'car', [20 5], [0 0], regressionCfg);
regressionRiskMap = updateOccupancyMap(regressionObstacle, egoState, regressionCfg);
regressionMap = regressionRiskMap.staticConservativeMap;
testPathStates = [10 0 0; 20 0 0; 30 0 0];
regressionMetrics = computePathMetrics(testPathStates, regressionMap, regressionCfg);
% Obstacle is at Y=5, path is at Y=0: clearance should be near 5 m minus
% footprint radius, but certainly positive and less than 10 m.
assert(regressionMetrics.minimumClearance > 0 && ...
    regressionMetrics.minimumClearance < 10, ...
    'Clearance Y-coordinate regression: value is implausible.');

disp('testPlanning: all checks passed.');

function track = makeTrack(id, actorClass, position, velocity, cfg)
    detection = struct('ID', id, 'Position', [position 0], ...
        'Velocity', [velocity 0], 'PerceivedClass', actorClass, ...
        'TrueClass', actorClass, 'PositionStd', [0.1 0.1 0.1], ...
        'VelocityStd', [0.1 0.1 0.1], 'IsDetected', true, 'Confidence', 0.95);
    track = initializeTracker(detection, cfg.sim.dt, cfg, 0);
end
