function data = prepareIDDData(cfg)
%PREPAREIDDDATA Inventory, parse, summarize, retain splits and select train classes.
checkIDDDiskSpace(cfg.outputDir,cfg.minimumConversionFreeGB,true);
inventory=inspectIDDStructure(cfg);[records,report]=parseIDDAnnotations(inventory,cfg);
splits=splitIDDData(records);counts=analyzeIDDClassBalance(records);
observed=unique(vertcat(splits.train.Labels));classes=string(cfg.targetLabels(:));
if isempty(classes),classes=observed(mapIDDClass(observed)~="unknown");end
if ~isfolder(cfg.outputDir),mkdir(cfg.outputDir);end
writetable(counts,fullfile(cfg.outputDir,'dataset_class_summary.csv'));
writetable(report,fullfile(cfg.outputDir,'conversion_report.csv'));
assert(~isempty(classes)&&all(ismember(classes,observed)),'IDD:Classes', ...
    'Classes must be observed in actual TRAIN annotations. Review discovered labels and configure targetLabels.');
% Seeded subset within each official split; FULL uses all. Validation never trains.
previous=rng;guard=onCleanup(@() rng(previous));rng(cfg.randomSeed,'twister'); %#ok<NASGU>
train=select(splits.train,cfg.trainLimit);val=select(splits.val,cfg.valLimit);
provenance=inventory.provenance;
provenance.validTrainCount=numel(splits.train);provenance.validValidationCount=numel(splits.val);
provenance.trainingImageCount=numel(train);provenance.validationImageCount=numel(val);
provenance.observedTrainingLabels=observed;provenance.classes=classes;
provenance.excludedLabels=setdiff(observed,classes);provenance.balancePolicy="No oversampling; uniform seeded subset only";
provenance.profile=cfg.profile;provenance.trainingImageFiles=string({train.ImageFile}).';
provenance.validationImageFiles=string({val.ImageFile}).';
data=struct('inventory',inventory,'records',records,'classSummary',counts,'conversionReport',report, ...
    'classes',classes,'train',convertIDDToTrainingTable(train,classes), ...
    'val',convertIDDToTrainingTable(val,classes),'provenance',provenance);
end
function selected=select(records,limit)
n=min(numel(records),limit);if n==numel(records),selected=records;else,indices=sort(randperm(numel(records),n));selected=records(indices);end
end
