function result = mainPhase12_5(options)
%MAINPHASE12_5 Opt-in IDD architecture/data/training entry. Never downloads IDD.
if nargin<1,options=struct();end
addpath(genpath(fileparts(mfilename('fullpath'))));cfg=getIDDConfig(options);
architecture=validateIDDArchitecture(cfg);environment=validateIDDEnvironment(cfg);
dataset=findIDDDataset(cfg);
result=struct('architecture',architecture,'environment',environment,'dataset',dataset, ...
    'parsing',"PENDING DATASET",'smokeTraining',"PENDING DATASET", ...
    'fullTraining',"NOT RUN",'validation',"NOT RUN",'canonical',"PASS", ...
    'message',dataset.message,'configuration',cfg);
if architecture.status~="COMPLETE",result.canonical="FAIL";end
if dataset.available
    stage="PARSING";
    try
        data=prepareIDDData(cfg);result.parsing="PASS";result.datasetProvenance=data.provenance;
        result.smokeTraining="NOT RUN - EXPLICIT TRAINING OPT-IN REQUIRED";
        if cfg.enabled&&cfg.runTraining
            if environment.trainingAvailable
                stage="TRAINING";
                training=trainIDDYOLOX(data,cfg);result.training=training;
                if cfg.profile=="SMOKE",result.smokeTraining=training.status;end
                if cfg.profile=="FULL",result.fullTraining=training.status;end
                result.validation=training.evaluation.status;
                stage="QUALITATIVE";
                cfg.detectorFile=training.savedModel;result.qualitative=mainIDDPerceptionDemo(cfg);
            else
                result.smokeTraining="NOT RUN - YOLOX CAPABILITY REQUIRED";
                result.message=environment.status;
            end
        end
    catch info
        result.message=string(info.message);result.errorIdentifier=string(info.identifier);
        if stage=="QUALITATIVE",result.qualitative=struct('status',"FAIL",'message',string(info.message));
        elseif result.parsing~="PASS",result.parsing="FAIL";
        elseif cfg.profile=="FULL",result.fullTraining="FAIL";
        else,result.smokeTraining="FAIL";end
    end
end
fprintf('%s',summarizeIDDTraining(result));
space=checkIDDDiskSpace(cfg.outputDir,.02);
if space.sufficient
    if ~isfolder(cfg.outputDir),mkdir(cfg.outputDir);end
    result.architectureFigure=drawIDDArchitecture(cfg.outputDir);
    stamp=char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
    result.statusFile=string(fullfile(cfg.outputDir,['phase12_5Status_' stamp '.mat']));
    saveStatus(result.statusFile,result);
    file=fullfile(cfg.outputDir,['phase12_5Status_' stamp '.txt']);fid=fopen(file,'w');
    assert(fid>=0,'IDD:StatusWrite','Could not write status file.');guard=onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid,'%s',summarizeIDDTraining(result));
else,fprintf('Status artifacts not written: insufficient free disk space.\n');end
end
function saveStatus(path,result)
% Status snapshots reference the model; they do not duplicate detector weights.
if isfield(result,'training')
    result.training=rmfield(result.training,intersect(fieldnames(result.training), ...
        {'detector','trainingInfo','history','evaluation'}));
end
save(path,'result');
end
