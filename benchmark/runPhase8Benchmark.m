function benchmark = runPhase8Benchmark(cfg, options)
%RUNPHASE8BENCHMARK Sanity-check and execute all scenarios through Phase 7.

    if nargin < 1 || isempty(cfg), cfg = config(); end
    if nargin < 2, options = struct(); end
    options = normalizeOptions(options);
    scenarios = getPhase8Scenarios(cfg);
    scenarioRuns = repmat(struct('scenario', [], 'sanity', [], ...
        'result', [], 'summary', [], 'detail', []), numel(scenarios), 1);
    summaryRows = cell(numel(scenarios), 1);
    benchmarkTimer = tic;
    for i = 1:numel(scenarios)
        scenario = scenarios{i};
        sanity = validatePhase8Scenario(scenario);
        result = runClosedLoopSimulation(scenario);
        [summary, detail] = collectPhase8Metrics(scenario, result);
        scenarioRuns(i) = struct('scenario', scenario, 'sanity', sanity, ...
            'result', result, 'summary', summary, 'detail', detail);
        summaryRows{i} = summary;
    end
    wallClockSeconds = toc(benchmarkTimer);
    summaryTable = struct2table(vertcat(summaryRows{:}));
    aggregate = aggregatePhase8Metrics(summaryTable, wallClockSeconds);
    benchmark = struct('scenarioRuns', scenarioRuns, ...
        'summaryTable', summaryTable, 'aggregate', aggregate, ...
        'savedFiles', struct());
    if options.saveResults
        benchmark.savedFiles = savePhase8Benchmark(benchmark, options.outputDirectory);
    end
    if options.generatePlots
        visualizePhase8Benchmark(benchmark);
    end
end

function options = normalizeOptions(options)
    if ~isfield(options, 'saveResults'), options.saveResults = false; end
    if ~isfield(options, 'generatePlots'), options.generatePlots = false; end
    if ~isfield(options, 'outputDirectory')
        projectRoot = fileparts(fileparts(mfilename('fullpath')));
        options.outputDirectory = fullfile(projectRoot, 'results', 'phase8');
    end
end
