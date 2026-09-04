%MAINPHASE7 Run deterministic closed-loop ego motion and online replanning.

clc;
clear;

disp('============================================================');
disp(' SIH26037 - Phase 7: Closed-Loop Motion and Online Replanning');
disp('============================================================');

if isempty(ver('nav'))
    error('mainPhase7:MissingToolbox', ...
        'Navigation Toolbox is required for closed-loop planning.');
end

cfg = config();
demo = createPhase7Demo(cfg);
resultPhase7 = runClosedLoopSimulation(demo);
m = resultPhase7.metrics;

fprintf('Termination:              %s\n', resultPhase7.terminationReason);
fprintf('Goal reached:             %d\n', m.goalReached);
fprintf('Collision occurred:       %d\n', m.collisionOccurred);
fprintf('Simulation time:          %.2f s\n', m.simulationTime);
fprintf('Distance travelled:       %.2f m\n', m.distanceTravelled);
fprintf('Initial path length:      %.2f m\n', resultPhase7.initialPathLength);
fprintf('Successful replans:       %d\n', m.numberOfReplans);
fprintf('Failed replans:           %d\n', m.numberOfFailedReplans);
fprintf('Mean / max speed:         %.2f / %.2f m/s\n', ...
    m.meanSpeed, m.maximumSpeed);
fprintf('Minimum actor distance:   %.2f m\n', m.minimumActorDistance);
fprintf('Mean / maximum risk:      %.3f / %.3f\n', m.meanRisk, m.maximumRisk);
fprintf('Time NORMAL:              %.2f s\n', m.timeInNORMAL);
fprintf('Time CAUTIOUS:            %.2f s\n', m.timeInCAUTIOUS);
fprintf('Time CONSERVATIVE_STOP:   %.2f s\n', m.timeInCONSERVATIVE_STOP);

states = {resultPhase7.log.acargState};
transitionIndices = find(~strcmp(states(2:end), states(1:end-1))) + 1;
for i = transitionIndices
    fprintf('State transition at %.2f s: %s -> %s (risk %.3f)\n', ...
        resultPhase7.log(i).time, resultPhase7.log(i - 1).acargState, ...
        resultPhase7.log(i).acargState, resultPhase7.log(i).totalRisk);
end
for i = 1:numel(resultPhase7.planEvents)
    event = resultPhase7.planEvents(i);
    fprintf('Plan event at %.2f s: success=%d initial=%d replaced=%d length=%.2f m\n', ...
        event.time, event.success, event.initialPlan, ...
        event.pathReplaced, event.newLength);
end

if demo.config.control.enableVisualization
    visualizeClosedLoop(resultPhase7, demo);
end
