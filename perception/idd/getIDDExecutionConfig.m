function cfg=getIDDExecutionConfig(overrides)
%GETIDDEXECUTIONCONFIG Phase 12.6 small model / constrained tiny smoke policy.
if nargin<1,overrides=struct();end
if isfield(overrides,'idd'),overrides=overrides.idd;end
profile="SMOKE";if isfield(overrides,'profile'),profile=upper(string(overrides.profile));end
if ~isfield(overrides,'pretrainedName')
    if profile=="SMOKE",overrides.pretrainedName="tiny-coco";else,overrides.pretrainedName="small-coco";end
end
cfg=getIDDConfig(overrides);
end
