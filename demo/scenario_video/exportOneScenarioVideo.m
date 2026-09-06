function row=exportOneScenarioVideo(item,o,folder,shotRoot)
%EXPORTONESCENARIOVIDEO Stream frames; exact timestamps, checkpointed sidecars.
loaded=load(item.SourceLog,'data');data=loaded.data;
assert(data.replayVerified&&string(data.scenario.name)==item.Scenario,'Video:Identity','Replay identity mismatch.');
phaseFolder=fullfile(folder,sprintf('phase%d',item.Phase));if ~isfolder(phaseFolder),mkdir(phaseFolder);end
shotFolder=fullfile(shotRoot,item.FileStem);if ~isfolder(shotFolder),mkdir(shotFolder);end
profiles=VideoWriter.getProfiles();
if any(strcmp({profiles.Name},'MPEG-4')),profile='MPEG-4';ext=".mp4";
elseif any(strcmp({profiles.Name},'Motion JPEG AVI')),profile='Motion JPEG AVI';ext=".avi";
else,error('Video:WriterUnavailable','No supported MP4/AVI writer.');end
file=string(fullfile(phaseFolder,item.FileStem+ext));sidecar=file+".mat";
assert(~isfile(file)&&~isfile(sidecar),'Video:NoOverwrite','Existing artifact requires validation/reuse, never overwrite.');
checkIDDDiskSpace(folder,o.minimumFreeGB,true);
writer=VideoWriter(file,profile);writer.FrameRate=o.frameRate;writer.Quality=o.quality;open(writer);
writerGuard=onCleanup(@() close(writer));
display=demoConfig();display.visible='off';ui=createDemoFigure(display);figureGuard=onCleanup(@() close(ui.figure));
r=data.result;times=[r.log.time];assert(all(diff(times)>0),'Video:Time','Non-increasing source timestamps.');
titleFrames=round(o.titleSeconds*o.frameRate);finalFrames=round(o.finalSeconds*o.frameRate);
copies=[diff(round((times-times(1))*o.frameRate)) 1];
assert(all(copies>=1),'Video:FrameRate','Frame rate would omit authoritative states.');
scheduleKind=[repmat("TITLE",titleFrames,1);repmat("REPLAY",sum(copies),1);repmat("FINAL",finalFrames,1)];
logFrame=[zeros(titleFrames,1);repelem((1:numel(times)).',copies(:));repmat(numel(times),finalFrames,1)];
simulationTime=NaN(size(logFrame));valid=logFrame>0;simulationTime(valid)=times(logFrame(valid));
timeline=table((1:numel(logFrame)).',(0:numel(logFrame)-1).'/o.frameRate,scheduleKind,logFrame,simulationTime, ...
    'VariableNames',{'VideoFrame','VideoTime','Kind','LogFrame','SimulationTime'});
title=renderScenarioVideoCard(data,item.Phase,"TITLE",o);
for j=1:titleFrames,writeVideo(writer,title);end
[~,key]=max([r.log.totalRisk]);shotFrames=[1 key numel(times)];shotNames=["initial" "highest_risk" "final"];
shotFiles=strings(3,1);
for i=1:numel(times)
    if mod(i,20)==1,checkIDDDiskSpace(folder,o.minimumDuringExportGB,true);end
    [pixels,state]=renderScenarioVideoFrame(ui,data,i,o);
    assert(state.time==times(i)&&state.risk==r.log(i).totalRisk,'Video:Fidelity','Rendered state differs from source.');
    for j=1:copies(i),writeVideo(writer,pixels);end
    for j=find(shotFrames==i)
        shotFiles(j)=fullfile(shotFolder,shotNames(j)+".png");imwrite(pixels,shotFiles(j));
    end
end
finalCard=renderScenarioVideoCard(data,item.Phase,"FINAL",o);
for j=1:finalFrames,writeVideo(writer,finalCard);end
close(writer);
row=table(item.VideoID,item.Scenario,item.Phase,file,item.SourceLog,string(data.outcome), ...
    r.goalReached,data.safeTermination,r.collisionOccurred,0,max([r.log.totalRisk]),r.numberOfReplans,"EXPORTED", ...
    'VariableNames',{'VideoID','Scenario','Phase','File','SourceLog','Outcome','GoalReached', ...
    'SafeTermination','Collision','Duration','PeakRisk','Replans','ExportStatus'});
row.SourceEvaluation=string(data.sourceFile);row.SimulationDuration=times(end)-times(1);
row.SourceSimulationTime=r.simulationTime;row.ExpectedFrames=height(timeline);row.FrameRate=o.frameRate;
row.Width=o.resolution(1);row.Height=o.resolution(2);row.ScreenshotCount=3;
row.InitialScreenshot=shotFiles(1);row.KeyScreenshot=shotFiles(2);row.FinalScreenshot=shotFiles(3);
row.KeySimulationTime=times(key);row.KeyVideoTime=o.titleSeconds+times(key)-times(1);
row.TitleSeconds=o.titleSeconds;row.FinalSeconds=o.finalSeconds;row.RecoveryTime=data.recoveryTime;
row.Concept=item.Concept;row.Challenge=item.Challenge;
row.TerminationReason=string(r.terminationReason);row.StatesEncountered=strjoin(unique(string({r.log.acargState}),'stable'),' -> ');
row.ReplayMode=string(data.replayMode);
row.RendererVersion=o.rendererVersion;
writetable(timeline,file+".timeline.csv");
events=buildDemoEvents(r);events.VideoTime=o.titleSeconds+events.Time-times(1);writetable(events,file+".events.csv");
summary=row;save(sidecar,'summary','-v7');
validation=validateScenarioVideo(row);row.Duration=validation.Duration;
row.ExportStatus="VALIDATED";summary=row;save(sidecar,'summary','validation','-v7');
end
