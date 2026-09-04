function evaluation = runPhase11Evaluation(cfg,options)
%RUNPHASE11EVALUATION Execute measured evaluation without RoadRunner runtime.

    if nargin<1||isempty(cfg),cfg=config();end
    if nargin<2,options=struct();end
    if ~isfield(options,'saveResults'),options.saveResults=true;end
    if ~isfield(options,'generateFigures'),options.generateFigures=true;end
    if ~isfield(options,'outputRoot'),options.outputRoot=[];end
    dataset=buildEvaluationDataset(cfg);
    baseline=runBaselineComparison(dataset,cfg);
    ablation=runACARGAblation(cfg);
    [robustness,phase9Source]=loadLatestPhase9Robustness();
    transitions=buildStateTransitionTable(dataset,robustness);
    riskTimeline=buildRiskResponseTimeline(dataset,robustness);
    overhead=measureACARGOverhead(dataset,cfg);
    statistical=computeStatisticalSummary(dataset,baseline,robustness,overhead,cfg);
    provenance=dataset.provenance;
    provenance.phase9SourceResultFile=phase9Source;
    provenance.roadRunnerRuntimeEvidence="PENDING_WINDOWS_OR_LINUX";
    provenance.frameTimingLimitation=["Equivalent frame wall-clock values divide measured run time " ...
        "by logged frame count; historical logs do not contain true per-frame maxima."];
    evaluation=struct('dataset',dataset,'baseline',baseline,'ablation',ablation, ...
        'robustness',robustness,'stateTransitions',transitions, ...
        'riskTimeline',riskTimeline,'acargOverhead',overhead, ...
        'statisticalSummary',statistical,'provenance',provenance, ...
        'tables',struct(),'savedFiles',struct());
    evaluation.tables=generatePhase11Tables(evaluation);
    if options.saveResults
        evaluation.savedFiles=savePhase11Results(evaluation,options.outputRoot);
        evaluation.provenance.sourceResultFile=evaluation.savedFiles.evaluationMat;
        if options.generateFigures
            evaluation.savedFiles.figureFiles=generatePhase11Figures( ...
                evaluation,evaluation.savedFiles.figureDirectory);
        end
        save(evaluation.savedFiles.evaluationMat,'evaluation','-v7.3');
        provenance=evaluation.provenance;
        save(evaluation.savedFiles.provenanceMat,'provenance');
    elseif options.generateFigures
        error('Phase11:FigureOutputRequired', ...
            'Figure generation requires saveResults and a timestamped output directory.');
    end
end
