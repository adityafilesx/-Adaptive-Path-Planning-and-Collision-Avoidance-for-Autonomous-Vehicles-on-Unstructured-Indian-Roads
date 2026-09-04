function [summary, detail] = collectRobustnessMetrics(scenario, result)
%COLLECTROBUSTNESSMETRICS Extract robustness, recovery, and explanation data.

    log = result.log;
    states = {log.acargState};
    transitionIndices = find(~strcmp(states(2:end), states(1:end-1))) + 1;
    sequence = states([1 transitionIndices]);
    dominantIDs = arrayfun(@dominantID, log);
    validDominant = isfinite(dominantIDs);
    dominantChangeIndices = find(validDominant(2:end) & validDominant(1:end-1) & ...
        dominantIDs(2:end) ~= dominantIDs(1:end-1)) + 1;
    speeds = [log.egoSpeed];
    unsafeResidualMotion = sum(~[log.pathSafe] & speeds > 0.05);
    unsafeMoving = sum(~[log.pathSafe] & [log.desiredSpeed] > 0.05);
    safeTermination = ~result.goalReached && ~result.collisionOccurred && ...
        (startsWith(result.terminationReason, 'Safely stopped') || ...
        strcmp(result.terminationReason, 'Maximum simulation time reached safely.'));
    [recovered, recoveryTime] = detectRecovery(scenario, result, transitionIndices);
    transitionExplanations = repmat(explainACARGDecision(log(1), scenario.config), 0, 1);
    for i = 1:numel(transitionIndices)
        transitionExplanations(end + 1, 1) = ...
            explainACARGDecision(log(transitionIndices(i)), scenario.config); %#ok<AGROW>
    end
    planEvents = result.planEvents;
    failed = 0;
    pathChanges = 0;
    if ~isempty(planEvents)
        failed = sum(~[planEvents.success]);
        pathChanges = sum([planEvents.pathReplaced]);
    end
    finiteOutputs = all(isfinite(result.egoHistory(:))) && ...
        all(isfinite([log.totalRisk])) && all(isfinite([log.desiredSpeed])) && ...
        all(isfinite([log.steering])) && all(isfinite([log.acceleration]));
    transitionTimes = [log(transitionIndices).time];
    if numel(transitionTimes) > 1
        minimumTransitionInterval = min(diff(transitionTimes));
    else
        minimumTransitionInterval = NaN;
    end
    summary = struct('Scenario', string(scenario.name), ...
        'Disturbance', string(scenario.disturbanceType), ...
        'GoalReached', result.goalReached, 'Collision', result.collisionOccurred, ...
        'SafeTermination', safeTermination, ...
        'TerminationReason', string(result.terminationReason), ...
        'SimulationTime', result.simulationTime, ...
        'DistanceTravelled', result.distanceTravelled, ...
        'MinimumActorDistance', result.metrics.minimumActorDistance, ...
        'MaximumRisk', max([log.totalRisk]), 'MeanRisk', mean([log.totalRisk]), ...
        'RiskRange', range([log.totalRisk]), ...
        'StateTransitions', numel(transitionIndices), ...
        'StateSequence', string(strjoin(sequence, ' -> ')), ...
        'NormalTime', result.metrics.timeInNORMAL, ...
        'CautiousTime', result.metrics.timeInCAUTIOUS, ...
        'StopTime', result.metrics.timeInCONSERVATIVE_STOP, ...
        'Replans', result.numberOfReplans, 'FailedReplans', failed, ...
        'PathChanges', pathChanges, ...
        'ReplanRequests', sum([log.replanRequested]), ...
        'MinimumSpeed', min(speeds), 'MeanSpeed', mean(speeds), ...
        'MaximumSpeed', max(speeds), ...
        'DominantActorChanges', numel(dominantChangeIndices), ...
        'MinimumTransitionInterval', minimumTransitionInterval, ...
        'ActivePathUnsafeMovingFrames', unsafeMoving, ...
        'UnsafeResidualBrakingFrames', unsafeResidualMotion, ...
        'RecoveryOccurred', recovered, 'RecoveryTime', recoveryTime, ...
        'FiniteOutputs', finiteOutputs);
    detail = struct('scenarioName', scenario.name, 'result', result, ...
        'transitionIndices', transitionIndices, ...
        'transitionExplanations', transitionExplanations, ...
        'dominantActorChangeIndices', dominantChangeIndices, ...
        'dominantActorIDs', dominantIDs, 'recoveryOccurred', recovered, ...
        'recoveryTime', recoveryTime);
end

function id = dominantID(frame)
    id = NaN;
    if isfield(frame.acargDiagnostics, 'dominantActorID')
        id = frame.acargDiagnostics.dominantActorID;
    end
end

function [recovered, recoveryTime] = detectRecovery(scenario, result, transitions)
    log = result.log;
    times = [log.time];
    recovered = false;
    recoveryTime = NaN;
    switch scenario.recoveryCriterion
        case 'confidence-restored'
            detected = reshape(arrayfun(@(x) detectedActor( ...
                x, scenario.actors(1).ID), log), 1, []);
            index = find(times > scenario.disturbanceWindow(2) & ...
                detected, 1);
        case 'detection-restored'
            detected = reshape(arrayfun(@(x) detectedActor( ...
                x, scenario.actors(1).ID), log), 1, []);
            index = find(times > scenario.disturbanceWindow(2) & ...
                detected, 1);
        case 'path-restored'
            events = result.planEvents;
            unsafeEvent = arrayfun(@(e) any(strcmp(e.reasons, ...
                'Upcoming active path is unsafe.')), events);
            candidate = find(unsafeEvent & [events.success], 1);
            if isempty(candidate), index = []; else
                index = find(times >= events(candidate).time, 1);
            end
        case 'planner-recovers'
            events = result.planEvents;
            failureTimes = [events(~[events.success]).time];
            if isempty(failureTimes), index = []; else
                successTimes = [events([events.success]).time];
                value = successTimes(successTimes > failureTimes(1));
                if isempty(value), index = []; else, index = find(times >= value(1), 1); end
            end
        case 'stop-exit'
            stop = strcmp({log.acargState}, 'CONSERVATIVE_STOP');
            index = find([false stop(1:end-1)] & ~stop & [log.egoSpeed] > 0.05, 1);
        case 'post-disturbance-motion'
            index = find(times > scenario.disturbanceWindow(2) & [log.egoSpeed] > 0.05, 1);
        otherwise
            if result.goalReached, index = numel(log); else, index = []; end
    end
    if ~isempty(index)
        recovered = true;
        recoveryTime = times(index(1));
    elseif strcmp(scenario.recoveryCriterion, 'goal') && result.goalReached
        recovered = true;
        recoveryTime = result.simulationTime;
    end
    if isempty(transitions) && strcmp(scenario.recoveryCriterion, 'stop-exit')
        recovered = false;
        recoveryTime = NaN;
    end
end

function value = detectedActor(frame, actorID)
    value = false;
    if isempty(frame.detections), return; end
    index = find([frame.detections.ID] == actorID, 1);
    if ~isempty(index), value = frame.detections(index).IsDetected; end
end
