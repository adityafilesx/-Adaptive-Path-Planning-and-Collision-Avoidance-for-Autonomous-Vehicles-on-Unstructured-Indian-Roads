function summary = mainPhase12(options)
%MAINPHASE12 Judge-facing diagnostic demo; autonomy configuration is frozen.
if nargin<1,options=struct();end
addpath(genpath(fileparts(mfilename('fullpath'))));
cfg=config();cfg.demo=demoConfig();
names=fieldnames(options);for i=1:numel(names),cfg.demo.(names{i})=options.(names{i});end
summary=runPhase12Demo(cfg.demo);
if isfield(summary,'goalReached')
    fprintf('Phase 12 %s | %s | goal %d | collision %d | %.1f s | %d replans\n', ...
        summary.mode,summary.scenario,summary.goalReached,summary.collisionOccurred, ...
        summary.completionTime,summary.numberOfReplans);
    fprintf('Replay values verified: %d. RoadRunner runtime: pending Windows/Linux.\n',summary.replayVerified);
end
end
