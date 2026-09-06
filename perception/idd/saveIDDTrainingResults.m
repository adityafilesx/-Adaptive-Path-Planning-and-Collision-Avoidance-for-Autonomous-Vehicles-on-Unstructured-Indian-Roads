function path = saveIDDTrainingResults(result,cfg)
%SAVEIDDTRAININGRESULTS Timestamped model, options, provenance and real metrics.
checkIDDDiskSpace(cfg.outputDir,.5,true);
folder=fullfile(cfg.outputDir,'models',result.runID);
assert(~isfolder(folder),'IDD:NoOverwrite','Model run already exists; refusing overwrite.');mkdir(folder);
path=string(fullfile(folder,'idd_yolox_detector.mat'));
save(path,'result','-v7.3');
writetable(getIDDClassMapping(),fullfile(folder,'class_mapping.csv'));
writetable(result.evaluation.globalSummary,fullfile(folder,'validation_summary.csv'),'WriteRowNames',true);
writetable(result.evaluation.perClass,fullfile(folder,'per_class_validation.csv'),'WriteRowNames',true);
end
