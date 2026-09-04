% mainPhase5.m
% Standalone Phase 5 entry point: Hybrid A* path planning over Phase 4
% conservative occupancy. No Automated Driving Toolbox is required.
%
% This script demonstrates:
%   - Phase 4 conservative occupancy generation (obstacle scene)
%   - validatorOccupancyMap with vehicle-footprint inflation
%   - plannerHybridAStar with forward-only motion
%   - 9-check path validation
%   - Path length, smoothness, and minimum clearance metrics
%   - Occupancy and path visualization

clc; clear; close all;

disp('=================================================================');
disp('  SIH26037 Phase 5: Hybrid A* Path Planning');
disp('  Adaptive Path Planning and Collision Avoidance');
disp('  for Autonomous Vehicles on Unstructured Indian Roads');
disp('=================================================================');
fprintf('\n');

%% Add project paths
addpath(genpath(fileparts(mfilename('fullpath'))));

%% Toolbox check
disp('Checking required toolboxes...');
v = ver;
toolboxes = {v.Name};

hasNav = any(strcmp(toolboxes, 'Navigation Toolbox'));
if ~hasNav
    error('mainPhase5:MissingToolbox', ...
        'Navigation Toolbox is required for plannerHybridAStar and validatorOccupancyMap.');
else
    disp('  Navigation Toolbox ............. installed');
end

hasSensorFusion = any(strcmp(toolboxes, 'Sensor Fusion and Tracking Toolbox'));
if hasSensorFusion
    disp('  Sensor Fusion and Tracking ..... installed');
else
    disp('  Sensor Fusion and Tracking ..... not installed (optional for Phase 5)');
end
fprintf('\n');

%% Load configuration and create demo scene
cfg = config();
disp('Creating Phase 5 deterministic demo scene...');
demo = createPhase5Demo(cfg);
fprintf('  Map world limits:  X [%.0f, %.0f] m  Y [%.0f, %.0f] m\n', ...
    demo.plannerData.ValidationMap.XWorldLimits(1), ...
    demo.plannerData.ValidationMap.XWorldLimits(2), ...
    demo.plannerData.ValidationMap.YWorldLimits(1), ...
    demo.plannerData.ValidationMap.YWorldLimits(2));
fprintf('  Map resolution:    %.0f cells/m\n', demo.plannerData.ValidationMap.Resolution);
fprintf('  Vehicle inflation: %.2f m\n', demo.plannerData.VehicleInflationRadius);
fprintf('  Start pose:        [%.1f, %.1f, %.2f]\n', demo.startPose);
fprintf('  Goal pose:         [%.1f, %.1f, %.2f]\n', demo.goalPose);
fprintf('\n');

%% Plan path
disp('Running Hybrid A* planner...');
tic;
pathData = planPath(demo.plannerData, demo.startPose, demo.goalPose, demo.config);
planTime = toc;

%% Report results
fprintf('\n');
disp('-----------------------------------------------------------------');
if pathData.success
    disp('  RESULT: PATH FOUND');
    fprintf('  Planning time:       %.3f s\n', planTime);
    fprintf('  Path states:         %d\n', size(pathData.states, 1));
    fprintf('  Path length:         %.2f m\n', pathData.metrics.pathLength);
    fprintf('  Path smoothness:     %.6f (mean |d-curvature|)\n', ...
        pathData.metrics.pathSmoothness);
    fprintf('  Minimum clearance:   %.2f m (grid-resolution limited)\n', ...
        pathData.metrics.minimumClearance);
    fprintf('  Max lateral offset:  %.2f m\n', max(abs(pathData.y)));
    fprintf('  Heading range:       [%.2f, %.2f] rad\n', ...
        min(pathData.theta), max(pathData.theta));
else
    disp('  RESULT: NO VALID PATH');
    fprintf('  Failure reason: %s\n', pathData.failureReason);
    if ~isempty(pathData.plannerError)
        fprintf('  Planner error:  %s\n', pathData.plannerError);
    end
    fprintf('  Planning time:  %.3f s\n', planTime);
end
disp('-----------------------------------------------------------------');
fprintf('\n');

%% Visualization
if demo.config.visualization.showPlanner
    % Occupancy risk map
    visualizeOccupancy(demo.riskMap, demo.egoState, demo.tracks);

    % Hybrid A* plan with vehicle footprints
    visualizePlan(demo.plannerData, pathData, demo.config);
end

disp('Phase 5 demo complete.');
