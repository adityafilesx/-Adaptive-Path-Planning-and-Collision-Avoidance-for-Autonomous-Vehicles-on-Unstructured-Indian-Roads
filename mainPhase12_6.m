function result=mainPhase12_6(options)
%MAINPHASE12_6 Independent IDD status and full 13-scenario video evidence.
if nargin<1,options=struct();end
addpath(genpath(fileparts(mfilename('fullpath'))));
if ~isfield(options,'idd'),options.idd=struct();end
if ~isfield(options,'video'),options.video=struct();end
result=struct();
try,result.idd=runIDDExecutionEvidence(options.idd);
catch info,result.idd=struct('executionStatus',"PENDING",'errorMessage',string(info.message));end
% Video work must run even when IDD data, detector or GPU is absent.
result.videos=exportAllScenarioVideos(options.video);
result.roadRunnerRuntime="PENDING WINDOWS/LINUX";
result.coreRegression="NOT RUN BY THIS ENTRY; SEE PHASE 12.6 REGRESSION AUDIT";
fprintf('\nPHASE 12.6 - FINAL PERCEPTION + VIDEO EVIDENCE\n');
if isfield(result.idd,'datasetStatus')
    a=result.idd;
    fprintf('IDD DATASET: %s\nIDD PARSING: %s\n',a.datasetStatus,a.parsing);
    fprintf('YOLOX: %s\nSUPPORTED GPU: %s\n',available(a.capability.YOLOXAvailable),available(a.capability.GPUAvailable));
    fprintf('SMOKE TRAINING: %s\nFULL TRAINING: %s\nIDD EVALUATION: %s\nIDD OVERLAYS: %d\n',a.smokeTraining,a.fullTraining,a.evaluation,a.overlayCount);
end
fprintf('PHASE 8 VIDEOS: %d/5\nPHASE 9 VIDEOS: %d/8\nVIDEOS VALIDATED: %d/13\nSCENARIO SCREENSHOTS: %d\n', ...
    result.videos.phase8Count,result.videos.phase9Count,result.videos.validatedCount,result.videos.screenshotCount);
fprintf('CORE REGRESSION: %s\nROADRUNNER RUNTIME: %s\n',result.coreRegression,result.roadRunnerRuntime);
stamp=string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
save(fullfile(result.videos.runDirectory,"phase12_6Status_"+stamp+".mat"),'result');
end
function s=available(v)
if v,s="AVAILABLE";else,s="UNAVAILABLE";end
end
