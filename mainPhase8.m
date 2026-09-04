%MAINPHASE8 Run and persist the five-scenario Phase 8 benchmark.

clc;
clear;

disp('============================================================');
disp(' PHASE 8 - MULTI-SCENARIO VALIDATION');
disp('============================================================');

cfg = config();
options = struct('saveResults', true, 'generatePlots', true);
phase8BenchmarkResult = runPhase8Benchmark(cfg, options);
table = phase8BenchmarkResult.summaryTable;

for i = 1:height(table)
    fprintf('\n%s\n', table.Scenario(i));
    fprintf('Goal reached: %s\n', yesNo(table.GoalReached(i)));
    fprintf('Collision: %s\n', yesNo(table.Collision(i)));
    fprintf('Safe termination: %s\n', yesNo(table.SafeTermination(i)));
    fprintf('Replans / failed: %d / %d\n', ...
        table.Replans(i), table.FailedReplans(i));
    fprintf('Max risk: %.3f\n', table.MaxRisk(i));
    fprintf('Min actor distance: %.2f m\n', table.MinActorDistance(i));
    fprintf('Simulation time: %.2f s\n', table.SimulationTime(i));
end

a = phase8BenchmarkResult.aggregate;
fprintf('\n============================================================\n');
fprintf('AGGREGATE\n');
fprintf('============================================================\n');
fprintf('Scenarios completed: %d / %d (%.1f%%)\n', ...
    a.completedScenarios, a.totalScenarios, 100 * a.completionRate);
fprintf('Goals reached: %d / %d (%.1f%%)\n', ...
    a.goalReachedCount, a.totalScenarios, 100 * a.goalReachRate);
fprintf('Collision-free: %d / %d (%.1f%%)\n', ...
    a.totalScenarios - a.collisionCount, a.totalScenarios, ...
    100 * a.collisionFreeRate);
fprintf('Mean replans: %.2f\n', a.meanReplansPerScenario);
fprintf('Mean replanning latency: %.2f ms\n', a.meanReplanLatencyMs);
fprintf('Worst replanning latency: %.2f ms\n', a.worstCaseReplanLatencyMs);
fprintf('Benchmark wall-clock time: %.2f s\n', a.totalBenchmarkWallClockSeconds);
fprintf('Saved benchmark: %s\n', phase8BenchmarkResult.savedFiles.benchmarkMat);
fprintf('Saved summary: %s\n', phase8BenchmarkResult.savedFiles.summaryCsv);

function text = yesNo(value)
    if value
        text = 'YES';
    else
        text = 'NO';
    end
end
