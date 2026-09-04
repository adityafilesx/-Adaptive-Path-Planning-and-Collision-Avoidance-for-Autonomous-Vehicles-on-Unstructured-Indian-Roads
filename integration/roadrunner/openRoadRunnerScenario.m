function result = openRoadRunnerScenario(rrApp, manifest, cfg)
%OPENROADRUNNERSCENARIO Open genuine generated scene/scenario assets only.

    if nargin < 3 || isempty(cfg), cfg = config(); end
    capability = isRoadRunnerAvailable(cfg);
    result = struct('status', "SKIPPED", 'sceneOpened', false, ...
        'scenarioOpened', false, 'message', capability.reason, ...
        'runtimeAPICalls', 0);
    if ~capability.runtimeReady, return; end
    scenePath = fullfile(capability.paths.sceneRoot, manifest.roadRunnerScene);
    scenarioPath = fullfile(capability.paths.scenarioRoot, manifest.roadRunnerScenario);
    if ~isfile(scenePath) || ~isfile(scenarioPath)
        result.status = "FAIL";
        result.message = "Genuine RoadRunner scene/scenario files are missing. Author them using the checked-in specification.";
        return;
    end
    try
        result.runtimeAPICalls = result.runtimeAPICalls + 1;
        openScene(rrApp, manifest.roadRunnerScene);
        result.sceneOpened = true;
        result.runtimeAPICalls = result.runtimeAPICalls + 1;
        openScenario(rrApp, manifest.roadRunnerScenario);
        result.scenarioOpened = true;
        result.status = "PASS";
        result.message = "RoadRunner scene and scenario opened.";
    catch info
        result.status = "FAIL";
        result.message = "RoadRunner scene/scenario open failed: " + string(info.message);
    end
end
