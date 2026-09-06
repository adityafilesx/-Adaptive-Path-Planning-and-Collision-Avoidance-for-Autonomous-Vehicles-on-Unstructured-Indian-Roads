function report=runIDDFullTraining(options,smokeProofFile)
%RUNIDDFULLTRAINING Guarded GPU entry; never launches an automatic CPU job.
if nargin<1,options=struct();end
if nargin<2,smokeProofFile="";end
addpath(genpath(fileparts(mfilename('fullpath'))));
if isfield(options,'idd'),options=options.idd;end
options.profile="FULL";options.pretrainedName="small-coco";
cfg=getIDDExecutionConfig(options);cap=validateIDDExecutionEnvironment(cfg);
report=struct('status',"PENDING GPU",'configuration',cfg,'capability',cap);
if ~cap.GPUAvailable
    fprintf(['FULL TRAINING PENDING GPU EXECUTION. Move the project to a MATLAB-supported NVIDIA GPU machine,\n' ...
        'install Computer Vision, Deep Learning, Parallel Computing and the YOLOX add-on.\n' ...
        'Set cfg.idd.root to the external licensed IDD-Detection extraction; retain official splits.\n' ...
        'Complete genuine SMOKE including reload/inference first. Then pass its smoke proof MAT,\n' ...
        'explicit enabled/runTraining flags, GPU execution and pretrained-weight opt-in.\n']);
    return
end
assert(cap.YOLOXAvailable&&cap.TrainingFunctionAvailable,'IDD:YOLOXUnavailable','Install the MATLAB YOLOX add-on.');
assert(cfg.enabled&&cfg.runTraining,'IDD:TrainingOptIn','Explicit FULL training enable flags are required.');
assert(cfg.executionEnvironment~="cpu",'IDD:ComputeRequired','FULL cannot use CPU mode.');
cfg.executionEnvironment="gpu";
dataset=findIDDDataset(cfg);assert(dataset.available,'IDD:DatasetRequired','%s',dataset.message);
checkIDDDiskSpace(cfg.outputDir,cfg.minimumFullTrainingFreeGB,true);
assert(isfile(smokeProofFile),'IDD:SmokeRequired','A completed genuine SMOKE proof is required before FULL.');
p=load(smokeProofFile,'smokeProof');assert(isfield(p,'smokeProof'),'IDD:SmokeRequired','Missing smokeProof.');
p=p.smokeProof;
assert(p.status=="PASS"&&p.datasetRoot==dataset.root&&p.reloadVerified&&p.inferenceVerified, ...
    'IDD:SmokeRequired','Smoke proof must cover this dataset, checkpoint, model reload and inference.');
[~,smoke]=loadIDDDetector(p.modelFile);
assert(smoke.profile=="SMOKE"&&smoke.trainedOnIDD&&~smoke.budgetStopped&&isfile(p.checkpointFile), ...
    'IDD:SmokeRequired','Smoke artifacts are absent/incomplete.');
data=prepareIDDData(cfg);
assert(isequal(string(p.classes(:)),string(data.classes(:))),'IDD:SmokeRequired','Smoke classes differ from FULL classes.');
report.training=trainIDDYOLOX(data,cfg);report.status=report.training.status;
cfg.detectorFile=report.training.savedModel;report.overlays=mainIDDPerceptionDemo(cfg);
fprintf('FULL training: %s | Validation: %s | %s\n',report.status,report.training.evaluation.status,report.training.savedModel);
end
