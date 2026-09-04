function groundTruth = getGroundTruth(scenario, egoVehicle)
%GETGROUNDTRUTH Read current non-ego states from a drivingScenario.
%   GROUNDTRUTH = GETGROUNDTRUTH(SCENARIO, EGOVEHICLE) returns one struct
%   per non-ego actor. The function only reads documented actor properties
%   when they are present, allowing it to tolerate toolbox release changes.

    if ~hasMember(scenario, 'Actors')
        error('getGroundTruth:InvalidScenario', ...
            'The scenario must expose an Actors property.');
    end

    actors = scenario.Actors;
    template = emptyState();
    groundTruth = repmat(template, 0, 1);
    egoID = readMember(egoVehicle, {'ActorID', 'ID'}, []);
    egoName = readMember(egoVehicle, {'Name'}, '');

    for actorIndex = 1:numel(actors)
        actor = actors(actorIndex);
        if isEgoActor(actor, egoVehicle, egoID, egoName)
            continue;
        end

        state = template;
        state.ID = readMember(actor, {'ActorID', 'ID'}, actorIndex);
        state.ClassID = readMember(actor, {'ClassID'}, NaN);
        state.Class = state.ClassID;
        state.ActorClass = class(actor);
        state.Name = readMember(actor, {'Name'}, '');
        state.Position = row3(readMember(actor, {'Position'}, [NaN NaN NaN]));
        state.Velocity = row3(readMember(actor, {'Velocity'}, [NaN NaN NaN]));
        state.Yaw = readMember(actor, {'Yaw'}, NaN);
        state.Orientation = readMember(actor, {'Orientation'}, []);
        state.Dimensions = [ ...
            readMember(actor, {'Length'}, NaN), ...
            readMember(actor, {'Width'}, NaN), ...
            readMember(actor, {'Height'}, NaN)];
        groundTruth(end + 1, 1) = state; %#ok<AGROW>
    end
end

function state = emptyState()
    state = struct('ID', [], 'ClassID', [], 'Class', [], 'ActorClass', '', 'Name', '', ...
        'Position', [NaN NaN NaN], 'Velocity', [NaN NaN NaN], 'Yaw', NaN, ...
        'Orientation', [], 'Dimensions', [NaN NaN NaN]);
end

function tf = isEgoActor(actor, egoVehicle, egoID, egoName)
    tf = false;
    try
        tf = isequal(actor, egoVehicle);
    catch
        % Some handle objects do not support equality in older releases.
    end
    if tf
        return;
    end

    actorID = readMember(actor, {'ActorID', 'ID'}, []);
    if ~isempty(egoID) && ~isempty(actorID) && isequal(actorID, egoID)
        tf = true;
        return;
    end
    actorName = readMember(actor, {'Name'}, '');
    tf = ~isempty(egoName) && ~isempty(actorName) && strcmp(actorName, egoName);
end

function value = readMember(item, names, fallback)
    value = fallback;
    for index = 1:numel(names)
        name = names{index};
        if hasMember(item, name)
            try
                value = item.(name);
                return;
            catch
                % Continue to the next documented, available property.
            end
        end
    end
end

function tf = hasMember(item, name)
    tf = (isstruct(item) && isfield(item, name)) || ...
        (~isstruct(item) && isprop(item, name));
end

function value = row3(value)
    value = double(value(:).');
    if numel(value) < 3
        value(end + 1:3) = NaN;
    end
    value = value(1:3);
end
