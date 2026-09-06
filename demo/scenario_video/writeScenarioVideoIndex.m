function writeScenarioVideoIndex(manifest,folder)
%WRITESCENARIOVIDEOINDEX Source-derived viewing notes, not a submission package.
fid=fopen(fullfile(folder,'VIDEO_INDEX.md'),'w');assert(fid>=0);guard=onCleanup(@() fclose(fid));
fprintf(fid,'# All-scenario video index\n\nMATLAB closed-loop simulation evidence. Not IDD perception or RoadRunner footage.\n\n');
fprintf(fid,'Every clip uses 10 fps, 1440 x 900, 1x simulation time, a %.1f-second title and a %.1f-second final card.\n\n',manifest.TitleSeconds(1),manifest.FinalSeconds(1));
fprintf(fid,'All saved states are shown; visual frame repetition does not interpolate risk or physical motion. `.timeline.csv` files map each encoded frame to its simulation state.\n\n');
for k=1:height(manifest)
    r=manifest(k,:);[~,name,ext]=fileparts(r.File);
    fprintf(fid,'## %02d — %s\n\n[Watch video](phase%d/%s%s)\n\n',r.VideoID,r.Scenario,r.Phase,name,ext);
    fprintf(fid,'- Tests: %s\n- Watch: %s.\n- Highest risk: **%.3f at simulation %.1f s** (video %.1f s).\n',r.Challenge,r.Concept,r.PeakRisk,r.KeySimulationTime,r.KeyVideoTime);
    fprintf(fid,'- Outcome: **%s**; goal %d, safe termination %d, collision %d.\n- Reason: %s\n- Replans: %d; governor states: %s.\n',r.Outcome,r.GoalReached,r.SafeTermination,r.Collision,r.TerminationReason,r.Replans,r.StatesEncountered);
    if isfinite(r.RecoveryTime),fprintf(fid,'- Source recovery criterion first met at %.1f s (video %.1f s); recovery does not necessarily mean goal completion.\n',r.RecoveryTime,r.TitleSeconds+r.RecoveryTime);end
    d=load(r.SourceLog,'data');l=d.data.result.log;
    ids=arrayfun(@(x) x.acargDiagnostics.dominantActorID,l);changes=find(isfinite(ids(2:end))&isfinite(ids(1:end-1))&ids(2:end)~=ids(1:end-1))+1;
    fprintf(fid,'- Dominant actor changes observed: %d.\n',numel(changes));
    if ~isempty(changes),fprintf(fid,'- First dominant-actor change: %.1f s.\n',l(changes(1)).time);end
    if contains(r.Scenario,'Urban'),fprintf(fid,'- Judge note: **Planner could not find a safe continuation → safe planning failure guard**, not a forced goal or an unhandled software error.\n');end
    if r.SafeTermination&&contains(r.TerminationReason,'Maximum'),fprintf(fid,'- Limitation: ended at the simulation horizon, not at the goal. Final physical speed %.2f m/s; do not call this a stationary stop.\n',l(end).egoSpeed);end
    fprintf(fid,'- Replay: `%s`\n- Authoritative source: `%s`\n- Validation: %s, %.1f video seconds, %d encoded frames.\n\n',r.SourceLog,r.SourceEvaluation,r.ExportStatus,r.Duration,r.ExpectedFrames);
end
end
