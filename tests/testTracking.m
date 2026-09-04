% testTracking.m
% Executable validation for Phase 3 class-conditioned tracking/prediction.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
cfg = config();
% Keep this deterministic validation independent of optional toolbox APIs.
cfg.tracking.preferTrackingKF = false;
dt = cfg.sim.dt;

detection = struct('ID', 101, 'Position', [0 0 0], ...
    'Velocity', [2 0 0], 'PerceivedClass', 'car', 'TrueClass', 'car', ...
    'PositionStd', [0.2 0.2 0.1], 'VelocityStd', [0.2 0.2 0.1], ...
    'IsDetected', true, 'Confidence', 0.9);

% TEST 1 — initialization creates a valid persistent tracker.
track = initializeTracker(detection, dt, cfg, 0);
assert(isequal(track.CurrentState, [0; 0; 2; 0]), ...
    'Initialization must use the detection state.');
assert(strcmp(track.Tracker.Backend, 'localCV'), ...
    'The deterministic test must use the portable backend.');

% TEST 2 — repeated position measurements maintain reasonable motion state.
for sample = 1:5
    detection.Position = [2 * sample * dt, 0, 0];
    [track, state] = updateTracker(track, detection, dt, cfg, sample * dt);
end
assert(abs(state(1) - 1.0) < 0.25 && abs(state(3) - 2.0) < 0.5, ...
    'Estimated constant-velocity motion is not reasonable.');

% TEST 3 — missed detections predict only and do not destroy the track.
miss = detection;
miss.IsDetected = false;
miss.Position = [NaN NaN NaN];
miss.Velocity = [NaN NaN NaN];
[track, missedState, missedCovariance, confidence, usedMeasurement, missedCount] = ...
    updateTracker(track, miss, dt, cfg, 0.6);
assert(~usedMeasurement && missedCount == 1 && all(isfinite(missedState)), ...
    'A missed detection must leave a predicted, usable track.');
assert(all(size(missedCovariance) == [4 4]), 'Track covariance is invalid.');

% TEST 4 — a recovered detection corrects the existing track.
recovery = detection;
recovery.Position = [1.4 0 0];
[track, recoveredState, ~, ~, usedMeasurement, missedCount] = ...
    updateTracker(track, recovery, dt, cfg, 0.7);
assert(usedMeasurement && missedCount == 0 && abs(recoveredState(1) - 1.4) < 0.3, ...
    'A returned detection must correct the persistent track.');

% TEST 5/6 — prediction spans the configured horizon and grows covariance.
predictionConfig = struct('ProcessNoise', track.ProcessNoise);
prediction = predictActor(track.CurrentState, track.CurrentCovariance, ...
    cfg.tracking.predictionHorizon, dt, predictionConfig);
assert(prediction.Time(end) >= 1.0 && prediction.Time(end) <= 2.0, ...
    'Prediction horizon must be approximately 1–2 seconds.');
assert(trace(prediction.PositionCovariance(:, :, end)) > ...
    trace(prediction.PositionCovariance(:, :, 1)), ...
    'Position covariance must grow over the prediction horizon.');

% TEST 7 — confidence remains bounded during detected and missed cycles.
assert(confidence >= 0 && confidence <= 1 && ...
    track.TrackingConfidence >= 0 && track.TrackingConfidence <= 1, ...
    'Tracking confidence must remain in [0, 1].');

% TEST 8 — class-specific parameters are configurable and distinct.
pedestrianDetection = detection;
pedestrianDetection.ID = 102;
pedestrianDetection.PerceivedClass = 'pedestrian';
pedestrianDetection.TrueClass = 'pedestrian';
pedestrianTrack = initializeTracker(pedestrianDetection, dt, cfg, 0);
assert(pedestrianTrack.ProcessNoise ~= track.ProcessNoise && ...
    pedestrianTrack.MaxMissedDetections ~= track.MaxMissedDetections, ...
    'Class conditioning must select distinct configured parameters.');

% TEST 9 — deterministic inputs produce deterministic tracking output.
trackA = initializeTracker(detection, dt, cfg, 0);
trackB = initializeTracker(detection, dt, cfg, 0);
[trackA, stateA, covarianceA] = updateTracker(trackA, recovery, dt, cfg, dt);
[trackB, stateB, covarianceB] = updateTracker(trackB, recovery, dt, cfg, dt);
assert(isequaln(stateA, stateB) && isequaln(covarianceA, covarianceB) && ...
    isequaln(trackA.CurrentState, trackB.CurrentState), ...
    'Deterministic perception input must yield deterministic tracking output.');

disp('testTracking: all checks passed.');
