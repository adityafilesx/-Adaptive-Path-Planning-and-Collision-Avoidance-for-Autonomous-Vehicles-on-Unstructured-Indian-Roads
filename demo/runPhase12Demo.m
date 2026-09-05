function summary = runPhase12Demo(options)
%RUNPHASE12DEMO Shared recorded-frame rendering for LIVE, REPLAY and EXPORT.
o=demoConfig();names=fieldnames(options);
for i=1:numel(names),o.(names{i})=options.(names{i});end
assert(ismember(upper(string(o.mode)),["LIVE","REPLAY","EXPORT"]),'Phase12:Mode','Unknown mode.');
assert(isscalar(o.playbackSpeed)&&isfinite(o.playbackSpeed)&&o.playbackSpeed>0,'Phase12:Speed','Playback speed must be positive.');
assert(o.frameRate>=10&&o.frameRate<=20,'Phase12:FPS','Use 10-20 fps.');
summary=struct('enabled',o.enabled);if ~o.enabled,return;end
if isfield(o,'data'),data=o.data;else,data=loadDemoData(o);end
ui=createDemoFigure(o);
if strcmpi(o.mode,'LIVE')
    liveData=data;liveData.isLive=true;liveData.result.log=struct([]);
    liveData.result.presentationFrames=struct([]);liveData.result.goalReached=false;
    liveData.result.collisionOccurred=false;liveData.result.numberOfReplans=0;
    data=captureDemoData(data,@observe);
else
    if ~data.replayVerified,data=captureDemoData(data);end
end
if strcmpi(o.mode,'EXPORT'),o.captureVideo=true;o.exportScreenshots=true;end
stamp=char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
dirs=struct();for name=["videos","screenshots","figures"]
    dirs.(name)=fullfile(o.outputRoot,char(name),stamp);mkdir(dirs.(name));
end
writer=[];videoFile='';videoStatus='NOT_REQUESTED';
if o.captureVideo
    profiles=VideoWriter.getProfiles();
    if any(strcmp({profiles.Name},'MPEG-4')),profile='MPEG-4';ext='.mp4';
    elseif any(strcmp({profiles.Name},'Motion JPEG AVI')),profile='Motion JPEG AVI';ext='.avi';
    else,profile='';ext='';videoStatus='UNSUPPORTED: no MPEG-4 or Motion JPEG AVI writer';end
    if ~isempty(profile)
        videoFile=fullfile(dirs.videos,[matlab.lang.makeValidName(data.scenario.name) ext]);
        writer=VideoWriter(videoFile,profile);writer.FrameRate=o.frameRate;open(writer);
        writerGuard=onCleanup(@() close(writer)); %#ok<NASGU>
        videoStatus='GENERATED';
    end
end
shots=selectDemoScreenshots(data);shotFiles=strings(height(shots),1);
times=[data.result.log.time];videoFrames=0;replayClock=tic;
indices=1:numel(times);
if strcmpi(o.mode,'LIVE') && ~o.captureVideo && ~o.exportScreenshots,indices=numel(times);end
for i=indices
    if ~isgraphics(ui.figure),error('Phase12:Closed','Demo window closed before completion.');end
    updateDemoFrame(ui,data,i,o);
    if o.exportScreenshots
        for k=find(shots.Frame==i).'
            shotFiles(k)=fullfile(dirs.screenshots,char(shots.Name(k)+".png"));
            exportgraphics(ui.figure,shotFiles(k),'Resolution',120,'BackgroundColor','white');
        end
    end
    if ~isempty(writer)
        frame=getframe(ui.figure);
        if i<numel(times)
            copies=round(times(i+1)/o.playbackSpeed*o.frameRate)-round(times(i)/o.playbackSpeed*o.frameRate);
        else,copies=max(1,round(o.frameRate*double(o.holdFinalFrame)));end
        for k=1:copies,writeVideo(writer,frame);end
        videoFrames=videoFrames+copies;
    end
    if o.animate && ~strcmpi(o.mode,'LIVE') && i<numel(times)
        pause(max(0,times(i+1)/o.playbackSpeed-toc(replayClock)));
    end
end
if ~isempty(writer),close(writer);end
artifacts=struct();
if strcmpi(o.mode,'EXPORT'),artifacts=exportDemoEvidence(data,dirs.figures);end
events=buildDemoEvents(data.result);eventFile=fullfile(o.outputRoot,['phase12DemoEvents_' stamp '.csv']);
writetable(events,eventFile);
shots.File=shotFiles;
summary=struct('enabled',true,'mode',upper(string(o.mode)),'scenario',data.scenario.name, ...
    'sourceFile',data.sourceFile,'replayVerified',data.replayVerified, ...
    'goalReached',data.result.goalReached,'collisionOccurred',data.result.collisionOccurred, ...
    'completionTime',times(end),'numberOfReplans',data.result.numberOfReplans, ...
    'peakRisk',max([data.result.log.totalRisk]),'metrics',data.result.metrics, ...
    'videoFile',videoFile,'videoStatus',videoStatus,'videoFrames',videoFrames, ...
    'frameRate',o.frameRate,'playbackSpeed',o.playbackSpeed,'screenshots',shots, ...
    'artifacts',artifacts,'eventFile',eventFile,'figureHandle',ui.figure);
summary.summaryFile=fullfile(o.outputRoot,['phase12DemoSummary_' stamp '.mat']);
savedSummary=rmfield(summary,'figureHandle');save(summary.summaryFile,'savedSummary');
if ~o.holdFinalFrame,close(ui.figure);end
    function observe(entry,presentation)
        if isempty(liveData.result.log)
            liveData.result.log=entry;liveData.result.presentationFrames=presentation;
        else
            liveData.result.log(end+1,1)=entry;
            liveData.result.presentationFrames(end+1,1)=presentation;
        end
        liveData.result.goalReached=presentation.goalReached;
        liveData.result.collisionOccurred=presentation.collisionOccurred;
        liveData.result.numberOfReplans=sum([liveData.result.log.plannerInvoked])-1;
        if isgraphics(ui.figure),updateDemoFrame(ui,liveData,numel(liveData.result.log),o);end
        if o.animate && numel(liveData.result.log)>1
            pause(data.scenario.config.control.dt/o.playbackSpeed);
        end
    end
end
