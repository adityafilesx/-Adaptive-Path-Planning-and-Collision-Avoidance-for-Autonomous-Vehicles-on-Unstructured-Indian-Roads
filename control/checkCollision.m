function [collision, minimumDistance] = checkCollision(egoState, actors, cfg)
%CHECKCOLLISION Check an oriented ego rectangle against circular actors.

    collision = false;
    minimumDistance = inf;
    halfLength = cfg.vehicle.length / 2;
    halfWidth = cfg.vehicle.width / 2;
    rotation = [cos(egoState.yaw) sin(egoState.yaw); ...
        -sin(egoState.yaw) cos(egoState.yaw)];
    for i = 1:numel(actors)
        delta = double(actors(i).Position(1:2)) - [egoState.x egoState.y];
        minimumDistance = min(minimumDistance, norm(delta));
        local = rotation * delta(:);
        dimensions = actorDimensions(actors(i), cfg);
        actorRadius = 0.5 * hypot(dimensions(1), dimensions(2));
        separation = [max(abs(local(1)) - halfLength, 0), ...
            max(abs(local(2)) - halfWidth, 0)];
        if norm(separation) <= actorRadius + cfg.control.collisionBuffer
            collision = true;
        end
    end
end

function dimensions = actorDimensions(actor, cfg)
    if isfield(actor, 'Dimensions') && numel(actor.Dimensions) >= 2 && ...
            all(isfinite(actor.Dimensions(1:2)))
        dimensions = actor.Dimensions(1:2);
        return;
    end
    actorClass = 'default';
    if isfield(actor, 'TrueClass')
        actorClass = actor.TrueClass;
    end
    footprint = getActorFootprint(actorClass, cfg);
    dimensions = [footprint.Length footprint.Width];
end
