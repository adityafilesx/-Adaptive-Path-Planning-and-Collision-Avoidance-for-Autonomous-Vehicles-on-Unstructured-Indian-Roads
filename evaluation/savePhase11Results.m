function files = savePhase11Results(evaluation,outputRoot)
%SAVEPHASE11RESULTS Save timestamped run without overwriting old evidence.

    if nargin<2||isempty(outputRoot)
        root=fileparts(fileparts(mfilename('fullpath')));
        outputRoot=fullfile(root,'results','phase11');
    end
    if ~isfolder(outputRoot),mkdir(outputRoot);end
    stamp=char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
    runDirectory=fullfile(outputRoot,['run_' stamp]);mkdir(runDirectory);
    figureDirectory=fullfile(runDirectory,'figures');mkdir(figureDirectory);
    provenanceDirectory=fullfile(runDirectory,'provenance');mkdir(provenanceDirectory);
    files=struct('runDirectory',string(runDirectory), ...
        'evaluationMat',string(fullfile(runDirectory,['phase11Evaluation_' stamp '.mat'])), ...
        'scenarioMetricsCsv',string(fullfile(runDirectory,'phase11ScenarioMetrics.csv')), ...
        'baselineComparisonCsv',string(fullfile(runDirectory,'phase11BaselineComparison.csv')), ...
        'ablationResultsCsv',string(fullfile(runDirectory,'phase11AblationResults.csv')), ...
        'stateTransitionsCsv',string(fullfile(runDirectory,'phase11StateTransitions.csv')), ...
        'robustnessSummaryCsv',string(fullfile(runDirectory,'phase11RobustnessSummary.csv')), ...
        'headlineMetricsCsv',string(fullfile(runDirectory,'phase11HeadlineMetrics.csv')), ...
        'provenanceMat',string(fullfile(provenanceDirectory,'phase11Provenance.mat')), ...
        'figureDirectory',string(figureDirectory),'figureFiles',strings(0,1));
    writetable(evaluation.tables.scenarioMetrics,files.scenarioMetricsCsv);
    writetable(evaluation.tables.baselineComparison,files.baselineComparisonCsv);
    writetable(evaluation.tables.ablationResults,files.ablationResultsCsv);
    writetable(evaluation.tables.stateTransitions,files.stateTransitionsCsv);
    writetable(evaluation.tables.robustnessSummary,files.robustnessSummaryCsv);
    writetable(evaluation.tables.headlineMetrics,files.headlineMetricsCsv);
    provenance=evaluation.provenance;
    save(files.provenanceMat,'provenance');
    save(files.evaluationMat,'evaluation','-v7.3');
end
