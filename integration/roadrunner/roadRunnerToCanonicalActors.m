function actors = roadRunnerToCanonicalActors(rrStates, manifest, transformValue)
%ROADRUNNERTOCANONICALACTORS Convert native-neutral runtime snapshots.

    if nargin < 3 || isempty(transformValue), transformValue = manifest; end
    actors = repmat(emptyActor(), 0, 1);
    for i = 1:numel(rrStates)
        state = rrStates(i);
        mapping = findMapping(state, manifest.actors);
        pose = roadRunnerPoseToCanonical(state, transformValue);
        if isempty(mapping)
            id = fieldOr(state, 'ID', fieldOr(state, 'ActorID', i));
            sourceClass = string(fieldOr(state, 'Class', fieldOr(state, 'Type', 'unknown')));
            [actorClass, ~] = mapRoadRunnerActorClass(sourceClass);
            name = string(fieldOr(state, 'Name', "RoadRunner actor " + i));
            dimensions = [4 1.8 1.5];
        else
            id = double(mapping.logicalActorID);
            actorClass = string(mapping.canonicalClass);
            name = string(mapping.roadRunnerActorName);
            dimensions = [mapping.dimensions.length mapping.dimensions.width mapping.dimensions.height];
        end
        timestamp = double(fieldOr(state, 'Timestamp', fieldOr(state, 'SimulationTime', NaN)));
        actors(end+1,1) = struct('ID', double(id), ...
            'TrueClass', char(actorClass), 'ClassID', NaN, ...
            'Class', char(actorClass), 'ActorClass', char(actorClass), ...
            'Name', char(name), 'Position', pose.Position, ...
            'Velocity', pose.Velocity, 'Yaw', pose.yaw, ...
            'Orientation', [], 'Dimensions', double(dimensions), ...
            'Confidence', 1.0, 'Timestamp', timestamp); %#ok<AGROW>
    end
end

function mapping = findMapping(state, mappings)
mapping = [];
if isfield(state,'Name')
    idx=find(strcmpi(string({mappings.roadRunnerActorName}),string(state.Name)),1);
    if ~isempty(idx), mapping=mappings(idx); return; end
end
nativeID=fieldOr(state,'ID',fieldOr(state,'ActorID',NaN));
if isfinite(double(nativeID))
    idx=find([mappings.logicalActorID]==double(nativeID),1);
    if ~isempty(idx), mapping=mappings(idx); end
end
end
function actor=emptyActor()
actor=struct('ID',0,'TrueClass','','ClassID',NaN,'Class','', ...
    'ActorClass','','Name','','Position',[0 0 0],'Velocity',[0 0 0], ...
    'Yaw',0,'Orientation',[],'Dimensions',[0 0 0], ...
    'Confidence',1,'Timestamp',NaN);
end
function value=fieldOr(s,name,fallback)
if isfield(s,name), value=s.(name); else, value=fallback; end
end
