function result = trainIDDYOLOX(data,cfg)
%TRAINIDDYOLOX Genuine-data transfer training with guarded profiles/checkpoints.
assert(cfg.enabled&&cfg.runTraining,'IDD:TrainingOptIn','Enable IDD and runTraining explicitly.');
assert(isstruct(data)&&isfield(data,'provenance')&&data.provenance.trainingImageCount>0, ...
    'IDD:DatasetRequired','Parsed genuine IDD records are required.');
assert(all(isfile(data.train.imageFilename))&&all(isfile(data.val.imageFilename)),'IDD:DatasetRequired','Dataset files are no longer available.');
cap=validateIDDEnvironment(cfg);assert(cap.trainingAvailable,'IDD:YOLOXUnavailable','%s',cap.status);
if cfg.profile~="SMOKE"
    assert(cap.gpuCount>0&&string(cfg.executionEnvironment)~="cpu",'IDD:ComputeRequired','DEVELOPMENT/FULL training requires a supported GPU; no long CPU training starts automatically.');
end
required=cfg.minimumTrainingFreeGB;if cfg.profile=="FULL",required=cfg.minimumFullTrainingFreeGB;end
checkIDDDiskSpace(cfg.outputDir,required,true);
stamp=string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));runID=cfg.profile+"_"+stamp;
runDir=fullfile(cfg.outputDir,'training',runID);checkpointDir=fullfile(runDir,'checkpoints');
if strlength(string(cfg.checkpointDir))>0
    checkpointDir=fullfile(cfg.checkpointDir,runID);checkIDDDiskSpace(checkpointDir,required,true);
end
mkdir(checkpointDir);cfg.checkpointDir=string(checkpointDir);
if strlength(string(cfg.resumeFile))>0
    loaded=load(cfg.resumeFile);detector=checkpointDetector(loaded);
    assert(isequal(string(detector.ClassNames(:)),string(data.classes(:))),'IDD:ResumeClasses','Checkpoint classes differ from current training classes.');
    resumePolicy="Detector-weight continuation; optimizer/scheduler state not restored";
    initialization=struct('source',string(cfg.resumeFile),'origin',"Saved YOLOX detector weights; continuation");
else
    detector=createIDDYOLOXDetector(data.classes,cfg);resumePolicy="Pretrained transfer initialization";
    initialization=struct('source',cfg.pretrainedName,'origin',"MathWorks COCO-pretrained initialization");
    if strlength(cfg.pretrainedDetectorFile)>0
        initialization=struct('source',string(cfg.pretrainedDetectorFile),'origin',"User-supplied YOLOX detector; pretrained origin not independently verified");
    end
end
previous=rng;randomGuard=onCleanup(@() rng(previous));rng(cfg.randomSeed,'twister'); %#ok<NASGU>
train=buildIDDDetectionDatastore(data.train);validation=buildIDDDetectionDatastore(data.val);
augmented=transform(train,@(x) augmentIDDTrainingData(x,cfg));
options=trainingOptions(char(cfg.optimizer),'InitialLearnRate',cfg.initialLearnRate, ...
    'MiniBatchSize',cfg.batchSize,'MaxEpochs',cfg.maxEpochs,'Shuffle','every-epoch', ...
    'ValidationData',validation,'ValidationFrequency',max(1,ceil(height(data.train)/cfg.batchSize)), ...
    'CheckpointPath',char(checkpointDir),'ExecutionEnvironment',char(cfg.executionEnvironment), ...
    'ResetInputNormalization',false,'Verbose',true,'Plots','none','OutputFcn',@monitor);
history=struct('Epoch',{},'Iteration',{},'TimeElapsed',{},'LearnRate',{},'TrainingLoss',{});
budgetStopped=false;timer=tic;
[detector,info]=trainYOLOXObjectDetector(augmented,detector,options);
elapsed=toc(timer);
% This known detector-object checkpoint can always be used for weight continuation.
checkpoint=struct('detector',detector,'info',info,'history',history,'provenance',data.provenance,'configuration',cfg); %#ok<NASGU>
save(fullfile(checkpointDir,'completed_call_checkpoint.mat'),'checkpoint','-v7.3');
result=struct('status',"PASS",'profile',cfg.profile,'runID',runID,'runDirectory',string(runDir), ...
    'checkpointDirectory',string(checkpointDir),'detector',detector,'trainingInfo',info, ...
    'history',history,'wallClockSeconds',elapsed,'hardware',cap,'provenance',data.provenance, ...
    'configuration',cfg,'trainingOptions',struct('optimizer',cfg.optimizer, ...
    'InitialLearnRate',cfg.initialLearnRate,'MiniBatchSize',cfg.batchSize, ...
    'MaxEpochs',cfg.maxEpochs,'Shuffle',"every-epoch",'ResetInputNormalization',false, ...
    'ValidationFrequency',max(1,ceil(height(data.train)/cfg.batchSize)), ...
    'ExecutionEnvironment',cfg.executionEnvironment,'CheckpointPath',string(checkpointDir)), ...
    'resumePolicy',resumePolicy,'initialization',initialization, ...
    'trainedOnIDD',true,'budgetStopped',budgetStopped,'finalTraining',cfg.profile=="FULL"&&~budgetStopped);
if budgetStopped,result.status="STOPPED: SMOKE WALL-TIME BUDGET";end %#ok<UNRCH> Set by nested trainer callback.
result.validationLossStatus="See original trainingInfo if provided by installed YOLOX API; never estimated from AP.";
try
    result.evaluation=evaluateIDDDetector(detector,data,cfg);
catch evaluationError
    result.evaluation=struct('status',"FAIL",'errorIdentifier',string(evaluationError.identifier), ...
        'message',string(evaluationError.message),'globalSummary',table(),'perClass',table());
end
result.savedModel=saveIDDTrainingResults(result,cfg);
    function stop=monitor(progress)
        needed={'Epoch','Iteration','TimeElapsed','LearnRate','TrainingLoss'};
        if all(isfield(progress,needed))
            entry=struct();for h=1:numel(needed),entry.(needed{h})=progress.(needed{h});end
            history(end+1)=entry;
        end
        stop=cfg.profile=="SMOKE"&&toc(timer)>cfg.maxSmokeSeconds;
        budgetStopped=budgetStopped||stop;
    end
end
function detector=checkpointDetector(loaded)
if isfield(loaded,'checkpoint'),loaded=loaded.checkpoint;end
if isfield(loaded,'result'),loaded=loaded.result;end
names=fieldnames(loaded);
for k=1:numel(names)
    if isa(loaded.(names{k}),'yoloxObjectDetector'),detector=loaded.(names{k});return;end
end
error('IDD:CheckpointFormat','Checkpoint has no yoloxObjectDetector object. Bare networks are not silently rewrapped; use the saved detector checkpoint/model.');
end
