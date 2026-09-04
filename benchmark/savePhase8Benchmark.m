function files = savePhase8Benchmark(benchmark, outputDirectory)
%SAVEPHASE8BENCHMARK Save timestamped reusable MAT and CSV summaries.

    if ~exist(outputDirectory, 'dir')
        mkdir(outputDirectory);
    end
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
    matPath = fullfile(outputDirectory, ['phase8Benchmark_' stamp '.mat']);
    csvPath = fullfile(outputDirectory, ['phase8ScenarioSummary_' stamp '.csv']);
    aggregatePath = fullfile(outputDirectory, ['phase8AggregateSummary_' stamp '.mat']);
    summaryTable = benchmark.summaryTable;
    aggregate = benchmark.aggregate;
    details = [benchmark.scenarioRuns.detail];
    sanityReports = [benchmark.scenarioRuns.sanity];
    save(matPath, 'summaryTable', 'aggregate', 'details', 'sanityReports');
    save(aggregatePath, 'aggregate');
    writetable(summaryTable, csvPath);
    files = struct('benchmarkMat', matPath, 'summaryCsv', csvPath, ...
        'aggregateMat', aggregatePath);
end
