function actors = applyPhase9ActorSchedule(actors, currentTime, schedule)
%APPLYPHASE9ACTORSCHEDULE Apply deterministic velocity changes to actor truth.

    for eventIndex = 1:numel(schedule)
        event = schedule(eventIndex);
        if currentTime + eps < event.Time
            continue;
        end
        actorIndex = find([actors.ID] == event.ActorID, 1);
        if isempty(actorIndex)
            continue;
        end
        if isfield(event, 'Velocity') && ~isempty(event.Velocity)
            velocity = double(event.Velocity(:).');
            actors(actorIndex).Velocity(1:2) = velocity(1:2);
            actors(actorIndex).Yaw = atan2(velocity(2), velocity(1));
        end
    end
end
