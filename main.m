% main.m
% Entry point for SIH26037 - Phase 3
% Adaptive Path Planning and Collision Avoidance for Autonomous Vehicles

clc; clear; close all;

disp('Starting SIH26037 Phase 3: Tracking and Short-Term Prediction');

%% Check environment and toolboxes
disp('Checking installed toolboxes...');
v = ver;
toolboxes = {v.Name};

hasAutomatedDriving = any(strcmp(toolboxes, 'Automated Driving Toolbox'));
if ~hasAutomatedDriving
    warning('Automated Driving Toolbox is NOT installed. Phase 3 requires this toolbox for drivingScenario.');
    disp('Please install the Automated Driving Toolbox to proceed.');
    % We don't return here so that the user can still see the error from drivingScenario if it's missing, 
    % or maybe they have an older version where it's called differently.
else
    disp(' - Automated Driving Toolbox is installed.');
end

%% Load configuration
addpath(genpath('.')); % Add all subfolders to path
cfg = config();
if cfg.tracking.preferTrackingKF && exist('trackingKF', 'file') == 2
    disp(' - trackingKF detected; using it when its installed API is compatible.');
else
    disp(' - trackingKF unavailable or disabled; using the local CV Kalman fallback.');
end
% Seed once for a reproducible *sequence* of distinct frame observations.
% simulatePerception also supports a seed for deterministic standalone calls.
runtimeCfg = cfg;
if ~isempty(cfg.perception.randomSeed)
    rng(cfg.perception.randomSeed, 'twister');
    runtimeCfg.perception.randomSeed = [];
end

%% Initialize Scenario
disp('Initializing driving scenario...');
try
    scenario = drivingScenario('SampleTime', cfg.sim.dt, 'StopTime', cfg.sim.stopTime);
catch ME
    error('Failed to create drivingScenario. Please ensure Automated Driving Toolbox is installed. Error: %s', ME.message);
end

% Add a straight road
roadCenters = [0 0 0; 120 0 0];
roadWidth = 7.0; % typical two-lane village road width
road(scenario, roadCenters, 'Width', roadWidth);

%% Add Actors
% Add Ego Vehicle
egoVehicle = vehicle(scenario, ...
    'ClassID', 1, ...
    'Length', cfg.ego.length, ...
    'Width', cfg.ego.width, ...
    'Position', cfg.ego.initialPos, ...
    'Name', 'Ego');

% Give ego a simple straight trajectory
egoTrajectory = [cfg.ego.initialPos; cfg.goal.pos];
egoSpeed = cfg.ego.initialSpeed;
trajectory(egoVehicle, egoTrajectory, egoSpeed);

% Add one Obstacle Vehicle
obstacleVehicle = vehicle(scenario, ...
    'ClassID', 1, ...
    'Length', cfg.obs.length, ...
    'Width', cfg.obs.width, ...
    'Position', cfg.obs.initialPos, ...
    'Name', 'Obstacle');

% Give obstacle a slower straight trajectory
obsTrajectory = [cfg.obs.initialPos; 100 cfg.obs.initialPos(2) 0];
obsSpeed = cfg.obs.initialSpeed;
trajectory(obstacleVehicle, obsTrajectory, obsSpeed);

%% Visualization setup
figure('Name', 'SIH26037 Phase 3', 'Position', [100, 100, 800, 600]);
plot(scenario, 'Waypoints', 'on', 'RoadCenters', 'on');
title('Phase 3: Synthetic Perception, Tracking, and Prediction');
xlabel('X (m)'); ylabel('Y (m)');
hold on;
hTruth = plot(nan, nan, 'go', 'MarkerSize', 8, 'LineWidth', 1.5, ...
    'DisplayName', 'Ground-truth actor');
hPerceived = plot(nan, nan, 'rx', 'MarkerSize', 8, 'LineWidth', 1.5, ...
    'DisplayName', 'Perceived actor');
hTracked = plot(nan, nan, 'bo', 'MarkerSize', 8, 'LineWidth', 1.5, ...
    'DisplayName', 'Tracked state');
hPrediction = plot(nan, nan, 'b--', 'LineWidth', 1.2, ...
    'DisplayName', 'Predicted trajectory');
hError = plot(nan, nan, 'r:', 'HandleVisibility', 'off');
legend([hTruth hPerceived hTracked hPrediction], 'Location', 'best');

% One persistent class-conditioned tracker is maintained per actor ID.
tracks = struct([]);

%% Simulation Loop
disp('Starting simulation loop...');
while advance(scenario)
    % Ground truth is used only to make controlled synthetic observations.
    groundTruth = getGroundTruth(scenario, egoVehicle);
    egoState = struct('Position', egoVehicle.Position, ...
        'Velocity', egoVehicle.Velocity);
    detections = simulatePerception(groundTruth, egoState, runtimeCfg);

    trackedXY = nan(0, 2);
    predictionX = nan(1, 0);
    predictionY = nan(1, 0);
    trackIndexForDetection = nan(numel(detections), 1);
    for actorIndex = 1:numel(detections)
        detection = detections(actorIndex);
        trackIndex = findTrack(tracks, detection.ID);
        if isempty(trackIndex)
            if ~detection.IsDetected
                continue;
            end
            tracks(end + 1) = initializeTracker(detection, cfg.sim.dt, ...
                cfg, scenario.SimulationTime); %#ok<SAGROW>
            trackIndex = numel(tracks);
        else
            tracks(trackIndex) = updateTracker(tracks(trackIndex), detection, ...
                cfg.sim.dt, cfg, scenario.SimulationTime);
        end
        trackIndexForDetection(actorIndex) = trackIndex;
        track = tracks(trackIndex);
        trackedXY(end + 1, :) = track.CurrentState(1:2).'; %#ok<AGROW>
        predictionConfig = struct('ProcessNoise', track.ProcessNoise);
        prediction = predictActor(track.CurrentState, track.CurrentCovariance, ...
            cfg.tracking.predictionHorizon, cfg.tracking.predictionStep, ...
            predictionConfig);
        predictionX = [predictionX, prediction.Position(:, 1).', NaN]; %#ok<AGROW>
        predictionY = [predictionY, prediction.Position(:, 2).', NaN]; %#ok<AGROW>
    end

    detected = detections([detections.IsDetected]);
    if isempty(groundTruth)
        truthXY = nan(0, 2);
    else
        truthXY = vertcat(groundTruth.Position);
        truthXY = truthXY(:, 1:2);
    end
    if isempty(detected)
        perceivedXY = nan(0, 2);
    else
        perceivedXY = vertcat(detected.Position);
        perceivedXY = perceivedXY(:, 1:2);
    end
    set(hTruth, 'XData', truthXY(:, 1), 'YData', truthXY(:, 2));
    set(hPerceived, 'XData', perceivedXY(:, 1), 'YData', perceivedXY(:, 2));
    set(hTracked, 'XData', trackedXY(:, 1), 'YData', trackedXY(:, 2));
    set(hPrediction, 'XData', predictionX, 'YData', predictionY);

    lineX = nan(1, 0);
    lineY = nan(1, 0);
    for actorIndex = 1:numel(detections)
        detection = detections(actorIndex);
        if detection.IsDetected
            lineX = [lineX, groundTruth(actorIndex).Position(1), ...
                detection.Position(1), NaN]; %#ok<AGROW>
            lineY = [lineY, groundTruth(actorIndex).Position(2), ...
                detection.Position(2), NaN]; %#ok<AGROW>
        end
        if detection.IsDetected
            perceivedText = sprintf('[%.1f, %.1f]', ...
                detection.Position(1), detection.Position(2));
            status = 'detected';
        else
            perceivedText = '[missed]';
            status = 'missed';
        end
        if ~isnan(trackIndexForDetection(actorIndex))
            track = tracks(trackIndexForDetection(actorIndex));
            trackedText = sprintf('[%.1f, %.1f]', ...
                track.CurrentState(1), track.CurrentState(2));
            trackingText = sprintf('trackConf=%.2f', track.TrackingConfidence);
        else
            trackedText = '[uninitialized]';
            trackingText = 'trackConf=0.00';
        end
        fprintf(['t=%5.2f s | ID=%s | true=[%.1f, %.1f] | perceived=%s | ', ...
            'tracked=%s | distance=%.1f m | confidence=%.2f | %s | %s\n'], ...
            scenario.SimulationTime, valueText(detection.ID), ...
            groundTruth(actorIndex).Position(1), groundTruth(actorIndex).Position(2), ...
            perceivedText, trackedText, detection.Distance, detection.Confidence, ...
            status, trackingText);
    end
    set(hError, 'XData', lineX, 'YData', lineY);
    drawnow limitrate;
    pause(0.01);
end

disp('Simulation complete.');

function index = findTrack(tracks, actorID)
%FINDTRACK Return the persistent track associated with one controlled ID.
    index = [];
    for candidate = 1:numel(tracks)
        if isequal(tracks(candidate).ActorID, actorID)
            index = candidate;
            return;
        end
    end
end

function text = valueText(value)
%VALUETEXT Format numeric or text actor identifiers for concise logging.
    if isnumeric(value) && isscalar(value)
        text = num2str(value);
    elseif ischar(value)
        text = value;
    elseif isstring(value) && isscalar(value)
        text = char(value);
    else
        text = '?';
    end
end
