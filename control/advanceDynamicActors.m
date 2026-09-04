function actors = advanceDynamicActors(actors, dt)
%ADVANCEDYNAMICACTORS Advance deterministic actor truth with constant velocity.

    for i = 1:numel(actors)
        velocity = double(actors(i).Velocity(:).');
        position = double(actors(i).Position(:).');
        position(1:2) = position(1:2) + velocity(1:2) * dt;
        actors(i).Position = position;
    end
end
