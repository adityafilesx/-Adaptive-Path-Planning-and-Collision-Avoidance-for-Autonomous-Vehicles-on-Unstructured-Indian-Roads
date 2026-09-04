function visualizePhase8Benchmark(benchmark)
%VISUALIZEPHASE8BENCHMARK Create a compact multi-metric comparison figure.

    table = benchmark.summaryTable;
    names = categorical(table.Scenario, table.Scenario, 'Ordinal', true);
    figure('Name', 'Phase 8 Multi-Scenario Benchmark', ...
        'Position', [60 60 1300 720]);
    tiledlayout(2, 3);
    nexttile; bar(names, [table.GoalReached table.Collision]);
    title('Outcome'); legend('Goal reached', 'Collision'); ylim([0 1.2]);
    nexttile; bar(names, table.MaxRisk); title('Maximum risk'); ylim([0 1]);
    nexttile; bar(names, table.Replans); title('Successful replans');
    nexttile; bar(names, table.MeanReplanLatencyMs); title('Mean replanning latency (ms)');
    nexttile; bar(names, table.MinActorDistance); title('Minimum actor distance (m)');
    nexttile; bar(names, [table.NormalTime table.CautiousTime table.StopTime], 'stacked');
    title('Time in ACARG states'); legend('NORMAL', 'CAUTIOUS', 'STOP');
end
