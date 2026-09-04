function manifest = loadRoadRunnerManifest(keyOrPath, cfg)
%LOADROADRUNNERMANIFEST Load one portable JSON scene/actor manifest.

    if nargin < 2 || isempty(cfg), cfg = config(); end
    paths = getRoadRunnerPaths(cfg);
    value = string(keyOrPath);
    if isfile(value)
        path = value;
    else
        key = lower(regexprep(value, '[^a-zA-Z0-9]+', ''));
        names = struct('village', 'villageRoad.json', ...
            'villageroad', 'villageRoad.json', ...
            'urban', 'urbanIntersection.json', ...
            'urbanintersection', 'urbanIntersection.json', ...
            'highway', 'highwayMerge.json', ...
            'highwaymerge', 'highwayMerge.json', ...
            'densemarket', 'denseMarket.json', ...
            'market', 'denseMarket.json', ...
            'cattle', 'cattleCrossing.json', ...
            'cattlecrossing', 'cattleCrossing.json');
        field = char(key);
        if ~isfield(names, field)
            error('RoadRunner:UnknownManifest', 'Unknown manifest key "%s".', value);
        end
        path = string(fullfile(paths.manifestRoot, names.(field)));
    end
    if ~isfile(path)
        error('RoadRunner:ManifestMissing', 'Manifest does not exist: %s', path);
    end
    manifest = jsondecode(fileread(path));
    manifest.manifestPath = char(path);
    report = validateRoadRunnerManifest(manifest);
    if ~report.valid
        error('RoadRunner:InvalidManifest', '%s', strjoin(report.errors, ' | '));
    end
end
