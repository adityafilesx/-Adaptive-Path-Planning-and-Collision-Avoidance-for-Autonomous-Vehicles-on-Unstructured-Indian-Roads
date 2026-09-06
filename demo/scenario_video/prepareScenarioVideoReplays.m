function inventory=prepareScenarioVideoReplays(o,folder)
%PREPARESCENARIOVIDEOREPLAYS Pin current evidence; enrich only missing vertices.
if strlength(o.sourceFile)>0
    source=string(o.sourceFile);loaded=load(source,'evaluation');e=loaded.evaluation;
else,[e,source]=loadLatestPhase11Evaluation();end
assert(e.provenance.benchmarkVersion=="POST_PHASE9_FIX"&& ...
    e.provenance.collisionRiskVersion=="PHASE9_TIME_WEIGHTED_DISTANCE_V1", ...
    'Video:StaleSource','Only authoritative post-fix Phase 11 evidence is accepted.');
identity=dir(source);catalog=scenarioVideoCatalog();
replayDir=fullfile(folder,'replays');if ~isfolder(replayDir),mkdir(replayDir);end
robust=getPhase9StressScenarios(e.provenance.configSnapshot);
paths=strings(13,1);mode=paths;outcomes=paths;challenge=paths;
for k=1:13
    if catalog.Phase(k)==8
        idx=find(arrayfun(@(r) string(r.scenario.name)==catalog.Scenario(k),e.dataset.scenarioRuns),1);
        assert(~isempty(idx),'Video:SourceMissing','Missing Phase 8 scenario.');
        r=e.dataset.scenarioRuns(idx);scenario=r.scenario;original=r.result;
        row=e.dataset.scenarioMetrics(e.dataset.scenarioMetrics.Scenario==catalog.Scenario(k),:);
        outcome=string(row.OutcomeClass);safe=logical(row.SafeTermination);recovery=NaN;
    else
        idx=find(string({e.robustness.scenarioRuns.scenarioName})==catalog.Scenario(k),1);
        assert(~isempty(idx),'Video:SourceMissing','Missing Phase 9 scenario.');
        r=e.robustness.scenarioRuns(idx);original=r.detail.result;
        scenario=robust{find(cellfun(@(s) string(s.name)==catalog.Scenario(k),robust),1)};
        safe=logical(r.summary.SafeTermination);recovery=r.detail.recoveryTime;
        outcome="FAILURE";if original.goalReached,outcome="GOAL_REACHED";elseif safe,outcome="SAFE_TERMINATION";end
    end
    paths(k)=fullfile(replayDir,catalog.FileStem(k)+".mat");
    if isfile(paths(k))
        saved=load(paths(k),'data');
        assert(saved.data.sourceFile==source&&isequaln(saved.data.result.log,original.log),'Video:ReplayMismatch','Existing replay does not match pinned source.');
        mode(k)=saved.data.replayMode;outcomes(k)=outcome;challenge(k)=string(scenario.description);continue
    end
    checkIDDDiskSpace(folder,o.minimumFreeGB,true);
    frames=[];mode(k)="SOURCE_PRESENTATION";
    if isfield(original,'presentationFrames'),frames=original.presentationFrames;end
    cache=fullfile(o.outputRoot,'cache',[matlab.lang.makeValidName(scenario.name) '.mat']);
    if isempty(frames)&&isfile(cache)
        c=load(cache,'sourceFile','log','presentationFrames');
        if strcmp(c.sourceFile,source)&&isequaln(c.log,original.log),frames=c.presentationFrames;mode(k)="READ_ONLY_PHASE12_CACHE";end
    end
    if isempty(frames)
        fprintf('REPLAY ENRICH %02d %s (one deterministic instrumentation run)\n',k,scenario.name);
        instrumented=scenario;instrumented.capturePresentation=true;instrumented.frameObserver=[];
        captured=runClosedLoopSimulation(instrumented);
        assert(isequaln(captured.egoHistory,original.egoHistory)&&isequaln(captured.actorHistory,original.actorHistory)&& ...
            isequaln(captured.log,original.log)&&isequaln(captured.metrics,original.metrics), ...
            'Video:ReplayMismatch','Instrumentation changed authoritative behavior for %s; export refused.',scenario.name);
        frames=captured.presentationFrames;mode(k)="EXACT_VERIFIED_INSTRUMENTATION";
        clear captured;
    end
    keep={'goalReached','collisionOccurred','simulationTime','numberOfReplans','terminationReason', ...
        'log','egoHistory','actorHistory','metrics','planEvents'};
    compact=struct();for j=1:numel(keep),compact.(keep{j})=original.(keep{j});end
    compact.presentationFrames=frames;
    data=struct('scenario',scenario,'result',compact,'sourceFile',source, ...
        'sourceIdentity',struct('bytes',identity.bytes,'datenum',identity.datenum), ...
        'sourceReference',sprintf('Phase %d / %s',catalog.Phase(k),scenario.name), ...
        'benchmarkVersion',e.provenance.benchmarkVersion,'metrics',original.metrics, ...
        'replayVerified',true,'replayMode',mode(k),'outcome',outcome,'safeTermination',safe, ...
        'recoveryTime',recovery,'concept',catalog.Concept(k)); %#ok<NASGU>
    checkIDDDiskSpace(folder,o.minimumDuringExportGB,true);save(paths(k),'data','-v7');
    outcomes(k)=outcome;challenge(k)=string(scenario.description);
    fprintf('REPLAY READY %02d %s | %s\n',k,scenario.name,outcome);
end
after=dir(source);assert(identity.bytes==after.bytes&&identity.datenum==after.datenum,'Video:SourceChanged','Source evidence was modified.');
inventory=catalog;inventory.SourceLog=paths;inventory.AuthoritativeSource=repmat(source,13,1);
inventory.ReplayMode=mode;inventory.Outcome=outcomes;inventory.Challenge=challenge;
writetable(inventory,fullfile(folder,'replay_inventory.csv'));
end
