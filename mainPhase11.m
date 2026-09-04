function phase11Result = mainPhase11(options)
%MAINPHASE11 Generate or load final simulation-based evaluation evidence.

    if nargin<1,options=struct();end
    if ~isfield(options,'reuseLatest'),options.reuseLatest=false;end
    fprintf('============================================================\n');
    fprintf(' PHASE 11 - FINAL EVALUATION\n');
    fprintf('============================================================\n');
    if options.reuseLatest
        [phase11Result,source]=loadLatestPhase11Evaluation();
        fprintf('Loaded saved evaluation: %s\n',source);
    else
        cfg=config();phase11Result=runPhase11Evaluation(cfg,options);
    end
    fprintf('%s',summarizePhase11(phase11Result));
    fprintf('Evidence scope: closed-loop MATLAB simulation on development hardware.\n');
    fprintf('RoadRunner runtime evidence: PENDING Windows/Linux validation.\n');
end
