function cfg=getIDDMilestone1Config(options)
%GETIDDMILESTONE1CONFIG Isolated tiny-model smoke settings; no automatic training.
if nargin<1,options=struct();end
if isfield(options,'idd'),options=options.idd;end
if isfield(options,'profile')
    assert(upper(string(options.profile))=="SMOKE",'IDD:MilestoneProfile','Milestone 1 only permits SMOKE, never DEVELOPMENT/FULL.');
end
defaults=getIDDExecutionConfig();
if ~isfield(options,'outputDir'),options.outputDir=fullfile(defaults.outputDir,'milestone1');end
if ~isfield(options,'trainLimit'),options.trainLimit=32;end
if ~isfield(options,'valLimit'),options.valLimit=32;end
cfg=getIDDExecutionConfig(options);
assert(cfg.profile=="SMOKE",'IDD:MilestoneProfile','Milestone 1 only permits SMOKE, never DEVELOPMENT/FULL.');
assert(cfg.pretrainedName=="tiny-coco",'IDD:MilestoneModel','Milestone 1 uses pretrained YOLOX-tiny.');
assert(cfg.augmentation.flipProbability==0,'IDD:MilestoneAugmentation','Milestone 1 uses photometry only; geometry changes require separate visual validation.');
assert(strlength(cfg.resumeFile)==0,'IDD:MilestoneResume','Milestone 1 requires a fresh transfer-learning smoke proof.');
end
