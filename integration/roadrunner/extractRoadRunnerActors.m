function [actors, diagnostics] = extractRoadRunnerActors(rrSimulation, manifest, simulationTime)
%EXTRACTROADRUNNERACTORS Read native actor state then cross adapter boundary.

    if nargin < 3, simulationTime = NaN; end
    actorSims = get(rrSimulation, "ActorSimulation");
    snapshots = repmat(struct('ID',NaN,'Name',"",'Pose',eye(4), ...
        'Velocity',[0 0 0],'Timestamp',simulationTime), 0, 1);
    expectedIDs = [manifest.actors.logicalActorID];
    expectedNames = string({manifest.actors.roadRunnerActorName});
    readErrors = strings(0,1);
    for i = 1:numel(actorSims)
        try
            id = double(getAttribute(actorSims(i), "ID"));
            name = actorName(actorSims(i));
            if ~ismember(id, expectedIDs) && ~ismember(name, expectedNames)
                continue;
            end
            snapshots(end+1,1) = struct('ID', id, 'Name', name, ...
                'Pose', double(getAttribute(actorSims(i), "Pose")), ...
                'Velocity', double(getAttribute(actorSims(i), "Velocity")), ...
                'Timestamp', double(simulationTime)); %#ok<AGROW>
        catch info
            readErrors(end+1) = "Actor " + i + ": " + string(info.message); %#ok<AGROW>
        end
    end
    actors = roadRunnerToCanonicalActors(snapshots, manifest);
    diagnostics = struct('nativeActorCount', numel(actorSims), ...
        'mappedActorCount', numel(actors), 'readErrors', readErrors, ...
        'actorCountMismatch', numel(actors)-numel(manifest.actors));
end

function name = actorName(actorSim)
name = "";
try
    name = string(get(actorSim, "Name"));
catch
    try
        value = convertToStruct(actorSim);
        if isfield(value,'Name'), name=string(value.Name); end
    catch
    end
end
end
