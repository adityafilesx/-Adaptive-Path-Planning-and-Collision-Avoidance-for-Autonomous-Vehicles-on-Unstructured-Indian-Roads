function files = savePhase9Results(phase9, outputDirectory)
%SAVEPHASE9RESULTS Save timestamp-safe MAT and CSV validation artifacts.

    if nargin < 2 || isempty(outputDirectory)
        projectRoot = fileparts(fileparts(mfilename('fullpath')));
        outputDirectory = fullfile(projectRoot, 'results', 'phase9');
    end
    if ~isfolder(outputDirectory), mkdir(outputDirectory); end
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
    files = struct( ...
        'robustnessMat', fullfile(outputDirectory, ['phase9Robustness_' stamp '.mat']), ...
        'scenarioCsv', fullfile(outputDirectory, ['phase9ScenarioSummary_' stamp '.csv']), ...
        'denseAuditMat', fullfile(outputDirectory, ['phase9DenseMarketAudit_' stamp '.mat']), ...
        'confidenceCsv', fullfile(outputDirectory, ['phase9ConfidenceSensitivity_' stamp '.csv']), ...
        'cpaCsv', fullfile(outputDirectory, ['phase9CPAComparison_' stamp '.csv']));
    robustness = phase9.robustness; %#ok<NASGU>
    save(files.robustnessMat, 'robustness');
    writetable(phase9.robustness.summaryTable, files.scenarioCsv);
    denseMarketAudit = phase9.denseMarketAudit; %#ok<NASGU>
    save(files.denseAuditMat, 'denseMarketAudit');
    writetable(phase9.confidenceSensitivity, files.confidenceCsv);
    writetable(phase9.cpaSensitivity, files.cpaCsv);
end
