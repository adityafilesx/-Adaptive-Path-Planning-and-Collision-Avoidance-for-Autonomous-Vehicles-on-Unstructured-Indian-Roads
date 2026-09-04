function table = buildRiskResponseTimeline(dataset,robustness)
%BUILDRISKRESPONSETIMELINE Aligned risk, state, speed, replan, dominant risk.

    runs={findBenchmark(dataset,'Sudden Cattle Crossing'), ...
        findRobustness(robustness,'Conservative Stop Recovery')};
    labels=["Sudden Cattle Crossing","Conservative Stop Recovery"];
    rows=cell(0,1);
    for r=1:2
        log=runs{r};
        for i=1:numel(log)
            dominant=NaN;
            if isfield(log(i).acargDiagnostics,'dominantActorRisk')
                dominant=log(i).acargDiagnostics.dominantActorRisk;
            end
            rows{end+1,1}=struct('Scenario',labels(r),'Time',log(i).time, ...
                'TotalRisk',log(i).totalRisk,'GovernorState',string(log(i).acargState), ...
                'DesiredSpeed',log(i).desiredSpeed,'ActualEgoSpeed',log(i).egoSpeed, ...
                'ReplanEvent',logical(log(i).plannerInvoked), ...
                'ReplanRequested',logical(log(i).replanRequested), ...
                'DominantActorRisk',dominant); %#ok<AGROW>
        end
    end
    table=struct2table(vertcat(rows{:}));
end
function log=findBenchmark(dataset,name)
idx=find(arrayfun(@(r) strcmp(r.scenario.name,name),dataset.scenarioRuns),1);
assert(~isempty(idx),'Phase11:TimelineScenarioMissing');log=dataset.scenarioRuns(idx).result.log;
end
function log=findRobustness(robustness,name)
idx=find(arrayfun(@(r) strcmp(r.scenarioName,name),robustness.scenarioRuns),1);
assert(~isempty(idx),'Phase11:TimelineRobustnessMissing');log=robustness.scenarioRuns(idx).detail.result.log;
end
