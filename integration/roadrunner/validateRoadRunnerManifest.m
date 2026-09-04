function report = validateRoadRunnerManifest(manifest)
%VALIDATEROADRUNNERMANIFEST Check schema, portability, IDs, and class mapping.

    errors = strings(0,1);
    required = {'schemaVersion','scenarioKey','scenarioName','roadRunnerScene', ...
        'roadRunnerScenario','egoActorName','bridgeMode','coordinateTransform', ...
        'egoInitialState','goalPose','actors'};
    for i = 1:numel(required)
        if ~isfield(manifest, required{i})
            errors(end+1) = "Missing manifest field: " + required{i}; %#ok<AGROW>
        end
    end
    if isempty(errors)
        if ~endsWith(string(manifest.roadRunnerScene), '.rrscene')
            errors(end+1) = "roadRunnerScene must name a future .rrscene asset.";
        end
        if ~endsWith(string(manifest.roadRunnerScenario), '.rrscenario')
            errors(end+1) = "roadRunnerScenario must name a future .rrscenario asset.";
        end
        portableManifest = manifest;
        if isfield(portableManifest, 'manifestPath')
            portableManifest = rmfield(portableManifest, 'manifestPath');
        end
        portableText = jsonencode(portableManifest);
        if contains(portableText, 'C:\\') || contains(portableText, '/Users/') || ...
                contains(portableText, '\\Users\\')
            errors(end+1) = "Manifest contains a machine-specific absolute path.";
        end
        try
            resolveRoadRunnerTransform(manifest.coordinateTransform);
        catch info
            errors(end+1) = "Invalid coordinate transform: " + string(info.message);
        end
        actors = manifest.actors;
        ids = arrayfun(@(a) double(a.logicalActorID), actors);
        if numel(unique(ids)) ~= numel(ids) || any(~isfinite(ids))
            errors(end+1) = "logicalActorID values must be finite and unique.";
        end
        names = string({actors.roadRunnerActorName});
        if numel(unique(names)) ~= numel(names) || any(strlength(names)==0)
            errors(end+1) = "RoadRunner actor names must be nonempty and unique.";
        end
        for i = 1:numel(actors)
            [mapped, detail] = mapRoadRunnerActorClass(actors(i).canonicalClass);
            if detail.usedFallback || mapped ~= string(actors(i).canonicalClass)
                errors(end+1) = "Unsupported canonical class for actor " + ids(i) + "."; %#ok<AGROW>
            end
            values = [poseValues(actors(i).initialPose), ...
                velocityValues(actors(i).velocity), dimensionValues(actors(i).dimensions)];
            if any(~isfinite(values)) || any(dimensionValues(actors(i).dimensions)<=0)
                errors(end+1) = "Actor " + ids(i) + " has invalid state/dimensions."; %#ok<AGROW>
            end
        end
        ego = poseValues(manifest.egoInitialState);
        goal = poseValues(manifest.goalPose);
        if any(~isfinite([ego goal]))
            errors(end+1) = "Ego initial state and goal must be finite.";
        end
    end
    report = struct('valid', isempty(errors), 'errors', errors, ...
        'actorCount', 0, 'scenarioKey', "");
    if isfield(manifest, 'actors'), report.actorCount = numel(manifest.actors); end
    if isfield(manifest, 'scenarioKey'), report.scenarioKey = string(manifest.scenarioKey); end
end

function v = poseValues(p)
v = [double(p.x) double(p.y) fieldOr(p,'z',0) double(p.yaw)];
end
function v = velocityValues(p)
v = [double(p.x) double(p.y) fieldOr(p,'z',0)];
end
function v = dimensionValues(p)
v = [double(p.length) double(p.width) double(p.height)];
end
function value = fieldOr(s,name,fallback)
if isfield(s,name), value=double(s.(name)); else, value=fallback; end
end
