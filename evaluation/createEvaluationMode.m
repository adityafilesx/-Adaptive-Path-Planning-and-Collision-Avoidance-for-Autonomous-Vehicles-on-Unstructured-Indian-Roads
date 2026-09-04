function [modeCfg,metadata] = createEvaluationMode(cfg,mode)
%CREATEEVALUATIONMODE Construct explicit copied configs for controlled studies.

    mode=upper(string(mode)); modeCfg=cfg;
    metadata=struct('mode',mode,'productionConfigModified',false, ...
        'usesAdaptiveEnvelope',true,'usesRiskSpeedControl',true, ...
        'usesRiskTriggeredReplanning',true,'description',"");
    switch mode
        case "FULL_ACARG"
            metadata.description="Frozen production ACARG configuration.";
        case "FIXED_MARGIN_BASELINE"
            modeCfg.governor.safetyEnvelope.riskScaling=0;
            modeCfg.governor.safetyEnvelope.stateScale.NORMAL=1;
            modeCfg.governor.safetyEnvelope.stateScale.CAUTIOUS=1;
            modeCfg.governor.safetyEnvelope.stateScale.CONSERVATIVE_STOP=1;
            modeCfg.governor.speedScale.NORMAL=1;
            modeCfg.governor.speedScale.CAUTIOUS=1;
            modeCfg.governor.speedScale.CONSERVATIVE_STOP=1;
            modeCfg.governor.thresholds.cautiousEnter=Inf;
            modeCfg.governor.thresholds.conservativeEnter=Inf;
            modeCfg.governor.replan.urgencyThreshold=Inf;
            modeCfg.control.riskChangeThreshold=Inf;
            metadata.usesAdaptiveEnvelope=false;
            metadata.usesRiskSpeedControl=false;
            metadata.usesRiskTriggeredReplanning=false;
            metadata.description=["Evaluation-only fixed physical/uncertainty margins, " ...
                "unit speed scale, and no ACARG-triggered replanning; path-safety, " ...
                "periodic replanning, collision checks, planner, controller, and dynamics remain active."];
        case "NO_CONFIDENCE_EFFECT"
            modeCfg.governor.risk.wConfidence=0;
            modeCfg.governor.risk.wUncertainty=0;
            modeCfg.governor.replan.confidenceUrgencyWeight=0;
            metadata.description="Evaluation-only removal of confidence/uncertainty risk and urgency terms.";
        case "NO_CLASS_WEIGHTING"
            names=fieldnames(modeCfg.governor.classWeights);
            baseline=modeCfg.governor.classWeights.car;
            for i=1:numel(names), modeCfg.governor.classWeights.(names{i})=baseline; end
            metadata.description="Evaluation-only equal normalized class weight for every supported class.";
        otherwise
            error('Phase11:UnknownEvaluationMode','Unknown evaluation mode %s.',mode);
    end
end
