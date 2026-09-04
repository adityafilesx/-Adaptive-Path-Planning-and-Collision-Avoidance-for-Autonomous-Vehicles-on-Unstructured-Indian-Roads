function phase10Result = mainPhase10(cfg)
%MAINPHASE10 Validate architecture everywhere; run genuine runtime when ready.

    if nargin<1 || isempty(cfg), cfg=applyRoadRunnerLocalConfiguration(config()); end
    fprintf('============================================================\n');
    fprintf(' PHASE 10 - ROADRUNNER INTEGRATION ARCHITECTURE\n');
    fprintf('============================================================\n');
    architecture=validateRoadRunnerArchitecture(cfg);
    for i=1:numel(architecture.checks)
        label='PASS'; if ~architecture.checks(i).passed, label='FAIL'; end
        fprintf('%-4s  %s -- %s\n',label,architecture.checks(i).name, ...
            architecture.checks(i).detail);
    end
    capability=architecture.environment.capability;
    runtimeResults=struct([]);
    if capability.runtimeReady
        runtimeResults(1)=runRoadRunnerBridge(cfg,'village');
        runtimeResults(2)=runRoadRunnerBridge(cfg,'urban');
        for i=1:numel(runtimeResults)
            fprintf('RoadRunner runtime %s: %s -- %s\n',runtimeResults(i).scenarioKey, ...
                runtimeResults(i).status,runtimeResults(i).message);
        end
    else
        fprintf('RoadRunner runtime validation: SKIPPED -- %s\n',capability.reason);
    end
    phase10Result=summarizeRoadRunnerValidation(architecture,runtimeResults);
    phase10Result.capability=capability;
    fprintf('PHASE 10 ARCHITECTURE: %s\n',phase10Result.architectureStatus);
    fprintf('ROADRUNNER RUNTIME VALIDATION: %s\n',phase10Result.runtimeValidationStatus);
    if ~architecture.passed
        error('mainPhase10:ArchitectureFailure','Phase 10 architecture validation failed.');
    end
end
