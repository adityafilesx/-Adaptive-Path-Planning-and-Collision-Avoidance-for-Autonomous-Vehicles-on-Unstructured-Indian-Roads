function metrics = summarizeClosedLoop(logEntries, result, cfg)
%SUMMARIZECLOSEDLOOP Derive Phase 7 metrics from structured step logs.

    if isempty(logEntries)
        speeds = 0;
        risks = 0;
        states = {''};
        actorDistances = inf;
    else
        speeds = [logEntries.egoSpeed];
        risks = [logEntries.totalRisk];
        states = {logEntries.acargState};
        actorDistances = [logEntries.minimumActorDistance];
    end
    dt = cfg.control.dt;
    metrics = struct();
    metrics.scenarioCompleted = result.goalReached && ~result.collisionOccurred;
    metrics.goalReached = result.goalReached;
    metrics.collisionOccurred = result.collisionOccurred;
    metrics.simulationTime = result.simulationTime;
    metrics.distanceTravelled = result.distanceTravelled;
    metrics.numberOfReplans = result.numberOfReplans;
    metrics.numberOfFailedReplans = result.numberOfFailedReplans;
    metrics.meanSpeed = mean(speeds);
    metrics.minimumSpeed = min(speeds);
    metrics.maximumSpeed = max(speeds);
    metrics.minimumActorDistance = min(actorDistances);
    metrics.maximumRisk = max(risks);
    metrics.meanRisk = mean(risks);
    metrics.timeInNORMAL = sum(strcmp(states, 'NORMAL')) * dt;
    metrics.timeInCAUTIOUS = sum(strcmp(states, 'CAUTIOUS')) * dt;
    metrics.timeInCONSERVATIVE_STOP = ...
        sum(strcmp(states, 'CONSERVATIVE_STOP')) * dt;
end
