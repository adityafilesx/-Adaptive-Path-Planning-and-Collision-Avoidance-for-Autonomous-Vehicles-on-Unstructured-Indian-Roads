function metrics = computeSafetyMetrics(scenario, result)
%COMPUTESAFETYMETRICS Derive defensible safety outcomes from one run.

    log=result.log; speeds=[log.egoSpeed];
    safeTermination=~result.goalReached && ~result.collisionOccurred && ...
        (startsWith(result.terminationReason,'Safely stopped') || ...
        strcmp(result.terminationReason,'Maximum simulation time reached safely.'));
    if result.goalReached && ~result.collisionOccurred
        outcome="GOAL_REACHED";
    elseif safeTermination
        outcome="SAFE_TERMINATION";
    else
        outcome="FAILURE";
    end
    [failureClass,failureExplained]=classifyFailure(result,outcome);
    stopEntries=sum(strcmp({log.acargState},'CONSERVATIVE_STOP') & ...
        [true ~strcmp({log(1:end-1).acargState},'CONSERVATIVE_STOP')]);
    unsafeMoving=sum(~[log.pathSafe] & [log.desiredSpeed]>0.05);
    unsafeResidualBraking=sum(~[log.pathSafe] & speeds>0.05);
    unsafeContinuation=0;
    for i=1:numel(result.planEvents)
        event=result.planEvents(i);
        unsafeFailure=~event.success && any(strcmp(event.reasons, ...
            'Upcoming active path is unsafe.'));
        if unsafeFailure
            index=find(abs([log.time]-event.time)<1e-9,1);
            if ~isempty(index) && log(index).desiredSpeed>0.05
                unsafeContinuation=unsafeContinuation+1;
            end
        end
    end
    [minCPA,minTimeCPA]=minimumCPA(log);
    metrics=struct('CollisionOccurred',logical(result.collisionOccurred), ...
        'CollisionFree',~result.collisionOccurred,'GoalReached',logical(result.goalReached), ...
        'SafeTermination',safeTermination,'OutcomeClass',outcome, ...
        'FailureClassification',failureClass,'FailureExplained',failureExplained, ...
        'MinimumActorDistance',result.metrics.minimumActorDistance, ...
        'ActivePathUnsafeMovingFrames',unsafeMoving, ...
        'UnsafeResidualBrakingFrames',unsafeResidualBraking, ...
        'ConservativeStopEvents',stopEntries, ...
        'FailedReplanUnsafeContinuationCount',unsafeContinuation, ...
        'MinimumPredictedCPADistance',minCPA,'MinimumTimeToCPA',minTimeCPA, ...
        'Scenario',string(scenario.name));
end

function [classification,explained]=classifyFailure(result,outcome)
if outcome~="FAILURE", classification="none"; explained=true; return; end
reason=lower(string(result.terminationReason));
if result.collisionOccurred || contains(reason,'collision')
    classification="collision";
elseif contains(reason,'repeated planning failures')
    classification="planner recovery guard";
elseif contains(reason,'maximum simulation time')
    classification="maximum simulation time";
elseif contains(reason,'safe path') || contains(reason,'path')
    classification="no safe path";
elseif contains(reason,'nan') || contains(reason,'runtime') || contains(reason,'numerical')
    classification="numerical/runtime failure";
elseif strlength(strtrim(reason))>0
    classification="other explicit reason";
else
    classification="unexplained";
end
explained=classification~="unexplained";
end

function [minimumDistance,minimumTime]=minimumCPA(log)
minimumDistance=Inf; minimumTime=Inf;
for i=1:numel(log)
    actors=log(i).actorRiskDetails;
    for j=1:numel(actors)
        if isfield(actors(j),'collisionDiagnostics')
            c=actors(j).collisionDiagnostics;
            if isfinite(c.cpaDistance) && c.cpaDistance<minimumDistance
                minimumDistance=c.cpaDistance;
                minimumTime=c.cpaTime;
            end
        end
    end
end
if isinf(minimumDistance), minimumDistance=NaN; end
if isinf(minimumTime), minimumTime=NaN; end
end
