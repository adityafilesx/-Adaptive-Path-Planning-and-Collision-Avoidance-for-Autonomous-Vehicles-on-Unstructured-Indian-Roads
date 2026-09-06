function report=runIDDExecutionEvidence(options)
%RUNIDDEXECUTIONEVIDENCE Genuine branch only; missing data never blocks video work.
if nargin<1,options=struct();end
cfg=getIDDExecutionConfig(options);dataset=findIDDDataset(cfg);cap=validateIDDExecutionEnvironment(cfg);
report=struct('datasetStatus',"NOT CONFIGURED",'dataset',dataset,'configuration',cfg, ...
    'capability',cap,'parsing',"PENDING",'smokeTraining',"NOT RUN", ...
    'fullTraining',"PENDING GPU",'evaluation',"NOT RUN",'overlayCount',0, ...
    'executionStatus',"IDD PERCEPTION EXECUTION PENDING",'canonicalProof',"PENDING GENUINE DETECTIONS");
if cap.GPUAvailable,report.fullTraining="NOT RUN - EXPLICIT FULL OPT-IN AND SMOKE REQUIRED";end
% Export a safe, portable full-profile configuration, not a trained artifact.
fullCfg=getIDDExecutionConfig(struct('profile',"FULL",'root',cfg.root,'outputDir',cfg.outputDir,'executionEnvironment',"gpu"));
space=checkIDDDiskSpace(cfg.outputDir,.05);
if space.sufficient
    if ~isfolder(cfg.outputDir),mkdir(cfg.outputDir);end
    report.fullConfigurationFile=string(fullfile(cfg.outputDir,'gpu_ready_full_configuration.mat'));
    save(report.fullConfigurationFile,'fullCfg','cap');
end
if ~dataset.available,return;end
report.datasetStatus="FOUND";
try
    data=prepareIDDData(cfg);report.parsing="PASS";report.provenance=data.provenance;
    buildIDDDetectionDatastore(data.train);buildIDDDetectionDatastore(data.val);
    f=data.inventory.files;split=["train";"val";"test"];images=zeros(3,1);annotations=images;
    for k=1:3,images(k)=sum(f.Split==split(k)&f.ImageExists);annotations(k)=sum(f.Split==split(k)&f.AnnotationExists);end
    writetable(table(split,images,annotations),fullfile(cfg.outputDir,'dataset_summary.csv'));
    counts=data.classSummary;counts.MappingReason=repmat("Observed literal label / semantic alias",height(counts),1);
    counts.MappingReason(counts.CanonicalClass=="unknown")="Unsupported label; controlled unknown fallback";
    writetable(counts,fullfile(cfg.outputDir,'class_summary.csv'));
    writetable(counts,fullfile(cfg.outputDir,'idd_class_mapping.csv'));
    provenance=data.provenance;save(fullfile(cfg.outputDir,'dataset_provenance.mat'),'provenance');
    if cfg.enabled&&cfg.runTraining&&cap.YOLOXAvailable&&cap.TrainingFunctionAvailable
        assert(cfg.profile=="SMOKE",'IDD:SmokeRequired','Use the guarded full entry after smoke proof.');
        trained=trainIDDYOLOX(data,cfg);cfg.detectorFile=trained.savedModel;
        [detector,saved]=loadIDDDetector(cfg.detectorFile);
        detections=runIDDInference(detector,data.val.imageFilename(1),cfg);packet=iddDetectionToCanonical(detections);
        assert(~packet.MetricReady&&trained.status=="PASS"&&saved.evaluation.status=="PASS",'IDD:SmokeIncomplete','Smoke pipeline did not finish.');
        smokeProof=struct('status',"PASS",'datasetRoot',dataset.root,'classes',data.classes, ...
            'modelFile',cfg.detectorFile,'checkpointFile',string(fullfile(trained.checkpointDirectory,'completed_call_checkpoint.mat')), ...
            'reloadVerified',true,'inferenceVerified',true);
        assert(isfile(smokeProof.checkpointFile),'IDD:SmokeIncomplete','Checkpoint absent.');
        save(fullfile(trained.runDirectory,'smoke_execution_proof.mat'),'smokeProof');
        report.smokeTraining="PASS";
    end
    if strlength(cfg.detectorFile)>0&&cap.YOLOXAvailable
        [detector,~]=loadIDDDetector(cfg.detectorFile);evaluation=evaluateIDDDetector(detector,data,cfg);
        report.evaluation=evaluation.status;report.modelFile=cfg.detectorFile;
        demo=mainIDDPerceptionDemo(cfg);report.overlayCount=numel(demo.files);
        report.canonicalProof="PASS - genuine image detections only; no metric state";
        if report.overlayCount>=20,report.executionStatus="IDD PERCEPTION EXECUTION COMPLETE";end
    end
catch info
    report.errorIdentifier=string(info.identifier);report.errorMessage=string(info.message);
    report.executionStatus="IDD EXECUTION BLOCKED - SEE ERROR";
end
end
