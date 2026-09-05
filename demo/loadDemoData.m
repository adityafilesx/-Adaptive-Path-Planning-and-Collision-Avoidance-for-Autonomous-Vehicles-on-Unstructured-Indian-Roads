function data = loadDemoData(options)
%LOADDEMODATA Load authoritative evidence; enrich missing paths by verified rerun.
[e,source]=loadLatestPhase11Evaluation();
if strcmpi(options.scenario,'Cattle Crossing') || strcmpi(options.scenario,'Sudden Cattle Crossing')
    idx=find(arrayfun(@(r) strcmp(r.scenario.name,'Sudden Cattle Crossing'),e.dataset.scenarioRuns),1);
    scenario=e.dataset.scenarioRuns(idx).scenario; original=e.dataset.scenarioRuns(idx).result;
elseif strcmpi(options.scenario,'Confidence Drop')
    scenario=createConfidenceDropScenario(config());
    idx=find(strcmp({e.robustness.scenarioRuns.scenarioName},'Confidence Drop'),1);
    original=e.robustness.scenarioRuns(idx).detail.result;
else
    error('Phase12:Scenario','Select Cattle Crossing or Confidence Drop.');
end
data=struct('scenario',scenario,'result',original,'sourceFile',source, ...
    'metrics',original.metrics,'evidence',e,'replayVerified',false);
end
