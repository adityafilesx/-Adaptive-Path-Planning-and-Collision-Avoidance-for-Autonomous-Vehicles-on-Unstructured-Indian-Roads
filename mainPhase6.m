%MAINPHASE6 Run the Adaptive Confidence-Aware Risk Governor (ACARG) demonstration.
%   This script runs a Phase 6 demo scenario in two modes:
%   1. Baseline (ACARG disabled): standard Phase 5 execution
%   2. Enhanced (ACARG enabled): applies per-actor adaptive safety envelopes

clc;
clear;

disp('============================================================');
disp(' SIH26037 - Phase 6: Adaptive Confidence-Aware Risk Governor');
disp('============================================================');

% Ensure Nav Toolbox is present
if isempty(ver('nav'))
    error('mainPhase6:MissingToolbox', ...
        'Navigation Toolbox is required for planning. Automated Driving Toolbox is NOT required.');
end

% Get config and override for demo
cfg = config();
cfg.visualization.showPlanner = false; % disable real-time drawing for speed
cfg.visualization.showVehicleFootprint = true;

% Create demo scenario (gives tracks, egoState, base riskMap)
demo = createPhase6Demo(cfg);

%% Run 1: Baseline (ACARG Disabled)
disp('--- RUN 1: Baseline (ACARG Disabled) ---');
demo.config.governor.enabled = false;

% Planning
plannerDataBaseline = createPlanner(demo.riskMap, demo.config);
pathDataBaseline = planPath(plannerDataBaseline, demo.startPose, demo.goalPose, demo.config);
pathMetricsBaseline = computePathMetrics(pathDataBaseline, plannerDataBaseline, demo.config);

fprintf('Baseline Path Valid: %d\n', pathDataBaseline.success);
if isfield(pathMetricsBaseline, 'metrics')
    fprintf('Baseline Min Clearance: %.2f m\n', pathMetricsBaseline.metrics.minimumClearance);
end

%% Run 2: Enhanced (ACARG Enabled)
disp(' ');
disp('--- RUN 2: Enhanced (ACARG Enabled) ---');
demo.config.governor.enabled = true;

% Run ACARG Orchestrator
acargDecision = acargGovernor(demo.tracks, demo.egoState, demo.config, []);

disp('ACARG Decision:');
fprintf('  State:          %s\n', acargDecision.state);
fprintf('  Total Risk:     %.2f\n', acargDecision.risk.totalRisk);
fprintf('  Safety Scale:   %.2f\n', acargDecision.safetyScale);
fprintf('  Speed Scale:    %.2f\n', acargDecision.speedScale);
fprintf('  Replan Urgency: %.2f (Requested: %d)\n', acargDecision.replanUrgency, acargDecision.replanRequested);

disp(' ');
disp('Actor Risk Details:');
for i = 1:numel(acargDecision.risk.actorRisk)
    ar = acargDecision.risk.actorRisk(i);
    fprintf('  Actor %d (%s):\n', ar.ActorID, ar.perceivedClass);
    fprintf('    Risk: %.2f (Conf: %.2f, Uncert: %.2f, CPA: %.2f, Dist: %.2f)\n', ...
        ar.risk, ar.confidence, ar.uncertainty, ar.collisionRisk, ar.distanceRisk);
    fprintf('    Safety Scale: %.2f\n', ar.safetyScale);
end

% Apply Adaptive Envelope
adaptiveRiskMap = applyAdaptiveSafetyEnvelope(demo.riskMap, acargDecision, demo.config);

% Planning
plannerDataEnhanced = createPlanner(adaptiveRiskMap, demo.config);
pathDataEnhanced = planPath(plannerDataEnhanced, demo.startPose, demo.goalPose, demo.config);
pathMetricsEnhanced = computePathMetrics(pathDataEnhanced, plannerDataEnhanced, demo.config);

fprintf('\nEnhanced Path Valid: %d\n', pathDataEnhanced.success);
if isfield(pathMetricsEnhanced, 'metrics')
    fprintf('Enhanced Min Clearance: %.2f m\n', pathMetricsEnhanced.metrics.minimumClearance);
end

%% Visualization Comparison
disp(' ');
disp('--- VISUALIZATION ---');
figure('Name', 'Phase 6 ACARG Comparison', 'Position', [100 100 1200 500]);

% Plot Baseline
subplot(1, 2, 1);
show(plannerDataBaseline.ValidationMap);
hold on;
plot(demo.egoState.Position(1), demo.egoState.Position(2), 'bo', 'MarkerSize', 8, 'LineWidth', 2);
if pathDataBaseline.success
    plot(pathDataBaseline.states(:,1), pathDataBaseline.states(:,2), 'b-', 'LineWidth', 2);
end
title('Baseline (Phase 5)');
axis equal;

% Plot Enhanced
subplot(1, 2, 2);
show(plannerDataEnhanced.ValidationMap);
hold on;
plot(demo.egoState.Position(1), demo.egoState.Position(2), 'bo', 'MarkerSize', 8, 'LineWidth', 2);
if pathDataEnhanced.success
    plot(pathDataEnhanced.states(:,1), pathDataEnhanced.states(:,2), 'r-', 'LineWidth', 2);
end
title(sprintf('ACARG Enhanced: %s', acargDecision.state));
axis equal;
