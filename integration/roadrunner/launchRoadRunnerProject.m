function result = launchRoadRunnerProject(cfg)
%LAUNCHROADRUNNERPROJECT Gated RoadRunner launcher; sole direct launch seam.

    if nargin < 1 || isempty(cfg), cfg = config(); end
    capability = isRoadRunnerAvailable(cfg);
    result = struct('status', "SKIPPED", 'opened', false, ...
        'app', [], 'message', capability.reason, 'runtimeAPICalls', 0);
    if ~capability.runtimeReady
        if capability.available && ~cfg.roadrunner.enabled
            result.message = "RoadRunner is available but integration is disabled in configuration.";
        end
        return;
    end
    try
        result.runtimeAPICalls = result.runtimeAPICalls + 1;
        result.app = roadrunner(ProjectFolder=char(capability.paths.projectRoot));
        result.opened = true;
        result.status = "PASS";
        result.message = "RoadRunner project opened.";
    catch info
        result.status = "FAIL";
        result.message = "RoadRunner project launch failed: " + string(info.message);
    end
end
