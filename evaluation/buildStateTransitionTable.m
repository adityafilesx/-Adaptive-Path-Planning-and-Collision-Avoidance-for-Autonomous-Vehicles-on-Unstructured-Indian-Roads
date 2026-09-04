function transitionTable = buildStateTransitionTable(dataset,robustness)
%BUILDSTATETRANSITIONTABLE Combine benchmark and robustness explanations.

    rows=cell(0,1);
    for i=1:numel(dataset.scenarioRuns)
        rows=appendTransitions(rows,string(dataset.scenarioRuns(i).scenario.name), ...
            "BENCHMARK",dataset.scenarioRuns(i).result.log);
    end
    for i=1:numel(robustness.scenarioRuns)
        rows=appendTransitions(rows,string(robustness.scenarioRuns(i).scenarioName), ...
            "ROBUSTNESS",robustness.scenarioRuns(i).detail.result.log);
    end
    if isempty(rows)
        emptyTable=table(strings(0,1),strings(0,1),zeros(0,1),strings(0,1), ...
            strings(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
            zeros(0,1),false(0,1),'VariableNames',variableNames());
        transitionTable=emptyTable;
    else
        transitionTable=struct2table(vertcat(rows{:}));
    end
end
function rows=appendTransitions(rows,scenario,source,log)
states=string({log.acargState}); indices=find(states(2:end)~=states(1:end-1))+1;
for j=1:numel(indices)
    index=indices(j); frame=log(index); before=log(index-1);
    threshold=NaN;actor=NaN;actorRisk=NaN;
    if isfield(frame.acargDiagnostics,'relevantThreshold')
        value=frame.acargDiagnostics.relevantThreshold;
        if isscalar(value),threshold=value;end
    end
    if isfield(frame.acargDiagnostics,'dominantActorID'),actor=frame.acargDiagnostics.dominantActorID;end
    if isfield(frame.acargDiagnostics,'dominantActorRisk'),actorRisk=frame.acargDiagnostics.dominantActorRisk;end
    rows{end+1,1}=struct('Scenario',scenario,'Source',source,'Time',frame.time, ...
        'PreviousState',string(before.acargState),'NewState',string(frame.acargState), ...
        'TotalRisk',frame.totalRisk,'RelevantThreshold',threshold, ...
        'DominantActor',actor,'DominantActorRisk',actorRisk, ...
        'DesiredSpeedBefore',before.desiredSpeed,'DesiredSpeedAfter',frame.desiredSpeed, ...
        'ReplanTriggered',logical(frame.plannerInvoked)); %#ok<AGROW>
end
end
function names=variableNames()
names={'Scenario','Source','Time','PreviousState','NewState','TotalRisk', ...
    'RelevantThreshold','DominantActor','DominantActorRisk', ...
    'DesiredSpeedBefore','DesiredSpeedAfter','ReplanTriggered'};
end
