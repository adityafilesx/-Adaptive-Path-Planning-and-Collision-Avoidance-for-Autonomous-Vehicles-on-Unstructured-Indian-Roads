function result=mainMilestone1IDD(options)
%MAINMILESTONE1IDD Genuine-data smoke bring-up; missing prerequisites are explicit.
% Configure cfg.idd.root in the CALLER, or the root default in getIDDConfig.m.
% No edits to core config.m are needed. This entry never runs FULL training.
if nargin<1,options=struct();end
addpath(genpath(fileparts(mfilename('fullpath'))));
cfg=getIDDMilestone1Config(options);cap=validateIDDExecutionEnvironment(cfg);
disk=checkIDDDiskSpace(cfg.outputDir,.05,true);
if ~isfolder(cfg.outputDir),mkdir(cfg.outputDir);end
result=struct('configuration',cfg,'capability',cap,'disk',disk, ...
    'datasetStatus',"NOT CONFIGURED",'parsing',"NOT RUN",'annotationValidation',"NOT RUN", ...
    'datastore',"NOT RUN",'augmentation',"NOT RUN",'modelInitialization',"NOT RUN", ...
    'smokeTraining',"PENDING DATASET",'modelReload',"NOT RUN",'inference',"NOT RUN", ...
    'canonical',"NOT RUN",'annotationOverlayCount',0,'augmentationOverlayCount',0, ...
    'inferenceOverlayCount',0,'fullTraining',"NOT PART OF MILESTONE 1", ...
    'regression',"NOT RUN BY THIS ENTRY; SEE SEPARATE REGRESSION AUDIT",'status',"PENDING");
result.yoloxEnvironment="INCOMPLETE";
if cap.details.trainingAvailable,result.yoloxEnvironment="PASS";
else,result.smokeTraining="PENDING YOLOX SUPPORT";end
try
    result.dataset=findIDDDataset(cfg);
    if result.dataset.available
        % A directory alone is not verified IDD. Inspect real layout/splits/files.
        checkIDDDiskSpace(cfg.outputDir,cfg.minimumConversionFreeGB,true);
        result.parsing="FAIL"; % Remains FAIL if actual parsing raises an error.
        data=prepareIDDData(cfg);result.datasetStatus="PASS";result.parsing="PASS";
        result.annotationValidation="FAIL";
        result.dataValidation=validateIDDMilestoneData(data,cfg);
        result.annotationValidation="PASS";result.datastore="PASS";result.augmentation="PASS";
        result.annotationOverlayCount=result.dataValidation.annotationOverlayCount;
        result.augmentationOverlayCount=result.dataValidation.augmentationOverlayCount;
        result.provenance=data.provenance;
        if cap.details.trainingAvailable
            result.smokeTraining="PENDING EXPLICIT SMOKE OPT-IN";
            trainingDisk=checkIDDDiskSpace(cfg.outputDir,cfg.minimumTrainingFreeGB);
            if trainingDisk.sufficient&&(cfg.allowWeightDownload||strlength(cfg.pretrainedDetectorFile)>0)
                detector=createIDDYOLOXDetector(data.classes,cfg); %#ok<NASGU>
                result.modelInitialization="PASS";
            end
            if ~trainingDisk.sufficient
                result.smokeTraining="PENDING SUITABLE COMPUTE / DISK";
            elseif cfg.enabled&&cfg.runTraining
                trained=trainIDDYOLOX(data,cfg);result.smokeTraining=trained.status;
                result.modelFile=trained.savedModel;result.trainingSeconds=trained.wallClockSeconds;
                result.checkpointFile=fullfile(trained.checkpointDirectory,'completed_call_checkpoint.mat');
                file=dir(result.checkpointFile);assert(~isempty(file)&&file.bytes>0,'IDD:Checkpoint','Checkpoint is absent/empty.');
                checkpoint=load(result.checkpointFile,'checkpoint');
                assert(isa(checkpoint.checkpoint.detector,'yoloxObjectDetector')&&isfield(checkpoint.checkpoint,'info'),'IDD:Checkpoint','Checkpoint detector/info invalid.');
                [detector,saved]=loadIDDDetector(result.modelFile);
                assert(saved.trainedOnIDD&&saved.profile=="SMOKE",'IDD:SmokeModel','Expected genuine smoke artifact.');
                result.modelReload="PASS";
                if trained.status=="PASS"
                    overlayDir=fullfile(cfg.outputDir,'inference_overlays',trained.runID);mkdir(overlayDir);
                    packets=cell(height(data.val),1);
                    for k=1:height(data.val)
                        detections=runIDDInference(detector,data.val.imageFilename(k),cfg);
                        packets{k}=iddDetectionToCanonical(detections);
                        assert(~packets{k}.MetricReady,'IDD:MetricLeak','Image detections must not contain metric state.');
                        path=fullfile(overlayDir,sprintf('%03d.png',k));
                        visualizeIDDDetections(data.val.imageFilename(k),detections,path);
                        pixels=imread(path);pixels=insertText(pixels,[5 5],'SMOKE MODEL - NOT FINAL ACCURACY');imwrite(pixels,path);
                    end
                    imageFiles=data.val.imageFilename;save(fullfile(overlayDir,'canonical_proof.mat'),'packets','imageFiles');
                    result.inferenceOverlayCount=height(data.val);result.inference="PASS";result.canonical="PASS";
                    result.status="SMOKE PIPELINE PASS - NOT FINAL ACCURACY";
                end
            end
        end
    end
catch info
    result.errorIdentifier=string(info.identifier);result.errorMessage=string(info.message);
    result.status="BLOCKED - SEE ERROR";
end
stamp=string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
result.statusFile=fullfile(cfg.outputDir,'milestone1Status_'+stamp+'.mat');
save(result.statusFile,'result');
summary=sprintf(['IDD DATASET: %s\nIDD PARSING: %s\nANNOTATION VALIDATION: %s\n' ...
    'YOLOX ENVIRONMENT: %s\nTRAINING DATASTORE: %s\nSMOKE TRAINING: %s\n' ...
    'MODEL RELOAD: %s\nGENUINE INFERENCE: %s\nIDD -> CANONICAL IMAGE DETECTIONS: %s\n' ...
    'FULL IDD TRAINING: %s\nFree disk: %.2f GiB; smoke guard %.2f GiB.\n' ...
    'Set cfg.idd.root in the caller; default: perception/idd/getIDDConfig.m (root field).\n' ...
    'Core config.m is intentionally unchanged. IDD_ROOT is an optional external override.\n%s\n'], ...
    result.datasetStatus,result.parsing,result.annotationValidation,result.yoloxEnvironment, ...
    result.datastore,result.smokeTraining,result.modelReload,result.inference,result.canonical, ...
    result.fullTraining,disk.availableGB,cfg.minimumTrainingFreeGB,cap.Reason);
environmentText=evalc('disp(cap);disp(cap.details.functions);disp(cap.details.toolboxes);disp(cap.details.addons);');
fid=fopen(fullfile(cfg.outputDir,'environment_report.txt'),'w');assert(fid>=0);guard=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n%s',summary,environmentText);fprintf('%s',summary);
if isfield(result,'errorMessage'),fprintf('BLOCKER: %s\n',result.errorMessage);end
end
