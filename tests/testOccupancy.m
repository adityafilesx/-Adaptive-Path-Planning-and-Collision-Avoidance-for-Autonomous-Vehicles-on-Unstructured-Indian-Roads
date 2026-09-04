% testOccupancy.m
% Deterministic validation for Phase 4 dynamic occupancy/risk representation.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
cfg = config();
cfg.tracking.preferTrackingKF = false;
egoState = struct('Position', [0 0], 'Velocity', [8 0]);

% TEST 1 — map initializes with configured resolution and world origin.
[map, metadata] = createOccupancyMap(cfg);
assert(isa(map, 'binaryOccupancyMap') && metadata.Resolution == cfg.occupancy.resolution, ...
    'Occupancy map did not initialize as configured.');

stationary = makeTrack(301, 'car', [20 0], [0 0], eye(4), cfg);

% TEST 2 — a stationary actor occupies cells.
stationaryMap = updateOccupancyMap(stationary, egoState, cfg);
assert(nnz(stationaryMap.conservativeOccupancyMask) > 0, ...
    'A stationary actor must mark occupied cells.');

% TEST 3 — motion produces a spatial prediction corridor.
moving = makeTrack(302, 'car', [20 2], [4 0], eye(4), cfg);
movingMap = updateOccupancyMap(moving, egoState, cfg);
firstMask = movingMap.layers(1).OccupancyMask;
lastMask = movingMap.layers(end).OccupancyMask;
assert(any(firstMask(:) ~= lastMask(:)), ...
    'A moving actor must create changing temporal occupancy layers.');

% TEST 4/7 — increased covariance increases the conservative envelope.
lowCovariance = makeTrack(303, 'car', [25 -2], [0 0], 0.05 * eye(4), cfg);
highCovariance = lowCovariance;
highCovariance.CurrentCovariance = 9 * eye(4);
lowMap = updateOccupancyMap(lowCovariance, egoState, cfg);
highMap = updateOccupancyMap(highCovariance, egoState, cfg);
assert(nnz(highMap.conservativeOccupancyMask) >= nnz(lowMap.conservativeOccupancyMask), ...
    'Greater uncertainty must not reduce conservative occupied area.');

% TEST 5 — configurable classes have distinct physical footprints.
carFootprint = getActorFootprint('car', cfg);
pedestrianFootprint = getActorFootprint('pedestrian', cfg);
assert(carFootprint.Length ~= pedestrianFootprint.Length || ...
    carFootprint.Width ~= pedestrianFootprint.Width, ...
    'Different classes must have distinct configured footprints.');

% TEST 6 — horizon controls temporal layer count.
shortCfg = cfg;
shortCfg.prediction.horizon = 0.5;
shortMap = updateOccupancyMap(moving, egoState, shortCfg);
assert(numel(shortMap.layers) < numel(movingMap.layers), ...
    'A shorter prediction horizon must produce fewer temporal layers.');

% TEST 8 — all stored normalized risk values are bounded.
assert(all(movingMap.conservativeRiskGrid(:) >= 0 & ...
    movingMap.conservativeRiskGrid(:) <= 1), ...
    'Risk grid must remain in [0,1].');

% TEST 9 — no actors returns an empty but valid representation.
emptyMap = updateOccupancyMap(struct([]), egoState, cfg);
assert(~any(emptyMap.conservativeOccupancyMask(:)) && ...
    ~any(emptyMap.conservativeRiskGrid(:)), ...
    'Empty actor input must create an empty map without crashing.');

% TEST 10/12 — invalid covariance is handled without NaN/Inf map values.
invalidCovariance = moving;
invalidCovariance.CurrentCovariance = NaN(4);
safeMap = updateOccupancyMap(invalidCovariance, egoState, cfg);
assert(all(isfinite(safeMap.conservativeRiskGrid(:))) && ...
    ~any(isnan(safeMap.conservativeOccupancyMask(:))), ...
    'Invalid covariance must not contaminate the occupancy/risk result.');

% TEST 11 — short missed-detection persistence respects configuration.
persisted = moving;
persisted.MissedDetectionCount = cfg.tracking.maxPredictionWithoutDetection;
persistedMap = updateOccupancyMap(persisted, egoState, cfg);
expired = persisted;
expired.MissedDetectionCount = cfg.tracking.maxPredictionWithoutDetection + 1;
expiredMap = updateOccupancyMap(expired, egoState, cfg);
assert(any(persistedMap.conservativeOccupancyMask(:)) && ...
    ~any(expiredMap.conservativeOccupancyMask(:)), ...
    'Missed-detection persistence must honor the configured limit.');

disp('testOccupancy: all checks passed.');

function track = makeTrack(id, actorClass, position, velocity, covariance, cfg)
    detection = struct('ID', id, 'Position', [position 0], ...
        'Velocity', [velocity 0], 'PerceivedClass', actorClass, ...
        'TrueClass', actorClass, 'PositionStd', [0.2 0.2 0.1], ...
        'VelocityStd', [0.2 0.2 0.1], 'IsDetected', true, 'Confidence', 0.9);
    track = initializeTracker(detection, cfg.sim.dt, cfg, 0);
    track.CurrentCovariance = covariance;
    track.Tracker.StateCovariance = covariance;
end
