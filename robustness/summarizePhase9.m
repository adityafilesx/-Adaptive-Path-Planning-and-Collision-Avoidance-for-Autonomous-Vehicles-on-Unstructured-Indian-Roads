function phase9 = summarizePhase9(robustness, denseAudit, confidenceTable, cpaTable)
%SUMMARIZEPHASE9 Package all Phase 9 evidence in one reusable structure.

    phase9 = struct('robustness', robustness, 'denseMarketAudit', denseAudit, ...
        'confidenceSensitivity', confidenceTable, ...
        'cpaSensitivity', cpaTable, 'savedFiles', struct());
end
