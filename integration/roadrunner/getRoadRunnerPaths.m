function paths = getRoadRunnerPaths(cfg)
%GETROADRUNNERPATHS Resolve portable repository and machine-local paths.

    if nargin < 1 || isempty(cfg), cfg = config(); end
    repositoryRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    projectRoot = string(cfg.roadrunner.projectRoot);
    source = "configuration";
    if strlength(strtrim(projectRoot)) == 0
        projectRoot = string(getenv('SIH_ROADRUNNER_PROJECT_ROOT'));
        source = "environment variable SIH_ROADRUNNER_PROJECT_ROOT";
    end
    if strlength(strtrim(projectRoot)) == 0 && ...
            exist('roadrunnerLocalConfig', 'file') == 2
        local = roadrunnerLocalConfig();
        if isstruct(local) && isfield(local, 'projectRoot')
            projectRoot = string(local.projectRoot);
        elseif ischar(local) || isstring(local)
            projectRoot = string(local);
        end
        source = "roadrunnerLocalConfig.m";
    end
    projectRoot = strtrim(projectRoot);
    if strlength(projectRoot) == 0
        source = "not configured";
        sceneRoot = ""; scenarioRoot = ""; assetRoot = "";
    else
        projectRoot = string(char(projectRoot));
        sceneRoot = string(fullfile(projectRoot, cfg.roadrunner.sceneDirectory));
        scenarioRoot = string(fullfile(projectRoot, cfg.roadrunner.scenarioDirectory));
        assetRoot = string(fullfile(projectRoot, cfg.roadrunner.assetDirectory));
    end
    roadRunnerRoot = fullfile(repositoryRoot, 'roadrunner');
    paths = struct('repositoryRoot', string(repositoryRoot), ...
        'integrationRoot', string(fileparts(mfilename('fullpath'))), ...
        'roadRunnerRoot', string(roadRunnerRoot), ...
        'manifestRoot', string(fullfile(roadRunnerRoot, 'manifests')), ...
        'specificationRoot', string(fullfile(roadRunnerRoot, 'specs')), ...
        'projectRoot', projectRoot, 'projectRootSource', source, ...
        'sceneRoot', sceneRoot, 'scenarioRoot', scenarioRoot, ...
        'assetRoot', assetRoot);
end
