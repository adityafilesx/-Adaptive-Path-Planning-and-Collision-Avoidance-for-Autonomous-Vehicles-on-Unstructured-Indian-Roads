function data = captureDemoData(data,observer)
%CAPTUREDEMODATA Record missing presentation fields and check canonical replay.
if nargin<2,observer=[];end
cacheRoot=fullfile(fileparts(fileparts(mfilename('fullpath'))),'results','phase12','cache');
if ~isfolder(cacheRoot),mkdir(cacheRoot);end
cacheFile=fullfile(cacheRoot,[matlab.lang.makeValidName(data.scenario.name) '.mat']);
if isempty(observer) && isfile(cacheFile)
    saved=load(cacheFile,'sourceFile','log','presentationFrames');
    if strcmp(saved.sourceFile,data.sourceFile) && isequaln(saved.log,data.result.log)
        data.result.presentationFrames=saved.presentationFrames;data.replayVerified=true;return
    end
end
scenario=data.scenario; scenario.capturePresentation=true; scenario.frameObserver=observer;
captured=runClosedLoopSimulation(scenario);
assert(isequaln(captured.egoHistory,data.result.egoHistory) && ...
    isequaln(captured.actorHistory,data.result.actorHistory) && ...
    isequaln(captured.log,data.result.log) && ...
    isequaln(captured.metrics,data.result.metrics), ...
    'Phase12:ReplayMismatch','Instrumented run differs from authoritative logged behavior.');
data.result.presentationFrames=captured.presentationFrames;
data.replayVerified=true;
sourceFile=data.sourceFile;log=data.result.log;presentationFrames=captured.presentationFrames; %#ok<NASGU>
save(cacheFile,'sourceFile','log','presentationFrames');
end
