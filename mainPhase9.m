%MAINPHASE9 Run robustness, failure-mode, and explainability validation.

clc;
clear;
disp('============================================================');
disp(' PHASE 9 - ROBUSTNESS AND ACARG EXPLAINABILITY');
disp('============================================================');

cfg = config();
denseAudit = analyzeDenseMarketStop(cfg);
robustness = runPhase9Robustness(cfg);
confidenceTable = runConfidenceSensitivity(cfg);
cpaTable = runCPASensitivity(cfg);
phase9Result = summarizePhase9( ...
    robustness, denseAudit, confidenceTable, cpaTable);
phase9Result.savedFiles = savePhase9Results(phase9Result, []);
visualizeACARGExplanation(phase9Result);

table = robustness.summaryTable;
for i = 1:height(table)
    fprintf('\n%s\n', table.Scenario(i));
    fprintf('Goal / collision / safe termination: %s / %s / %s\n', ...
        yesNo(table.GoalReached(i)), yesNo(table.Collision(i)), ...
        yesNo(table.SafeTermination(i)));
    fprintf('State sequence: %s\n', table.StateSequence(i));
    fprintf('Maximum risk: %.3f | Replans / failed: %d / %d\n', ...
        table.MaximumRisk(i), table.Replans(i), table.FailedReplans(i));
    fprintf('Recovered: %s | Unsafe forward-command frames: %d\n', ...
        yesNo(table.RecoveryOccurred(i)), table.ActivePathUnsafeMovingFrames(i));
end

a = robustness.aggregate;
fprintf('\nDense Market legacy classification: %s\n', denseAudit.classification);
fprintf('Legacy STOP: totalRisk %.6f vs threshold %.2f; actor %d at %.3f m.\n', ...
    denseAudit.transition.TotalRisk, denseAudit.stopEntryThreshold, ...
    denseAudit.transition.DominantActorID, denseAudit.transition.PhysicalDistance);
fprintf('Post-fix Dense Market: goal=%s, collision=%s, maximum risk=%.3f.\n', ...
    yesNo(denseAudit.postFix.goalReached), ...
    yesNo(denseAudit.postFix.collisionOccurred), denseAudit.postFix.maximumRisk);
fprintf('\nRobustness: %d scenarios, %d collision-free, %d recovered, %d unexplained failures.\n', ...
    a.totalScenarios, a.collisionFreeCount, a.recoveredCount, a.unexplainedFailureCount);
fprintf('Wall-clock time: %.2f s\n', a.wallClockSeconds);
fprintf('Saved result: %s\n', phase9Result.savedFiles.robustnessMat);

function text = yesNo(value)
    if value, text = 'YES'; else, text = 'NO'; end
end
