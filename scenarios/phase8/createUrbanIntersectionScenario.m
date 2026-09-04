function scenario = createUrbanIntersectionScenario(config)
%CREATEURBANINTERSECTIONSCENARIO Crossing car and two-wheeler conflict.

    if nargin < 1, config = feval('config'); end
    ego = egoState(0, 0, 0, 0);
    actors(1) = makePhase8Actor(401, 'car', [65 18], [0 -2.2], ...
        [4.7 1.8], 'Crossing car');
    actors(2) = makePhase8Actor(402, 'auto', [90 -18], [0 2.2], ...
        [3.2 1.5], 'Crossing auto-rickshaw');
    scenario = makePhase8Scenario('Unsignalized Urban Intersection', ...
        'Two crossing actors create predicted conflicts without signal logic.', ...
        ego, [100 0 0], actors, 24, ...
        'Risk-driven slowing and rerouting through crossing traffic', 802, config);
    scenario.config.control.baseSpeed = 7.5;
    scenario.config.occupancy.worldLimits(2, :) = [-40 40];
end

function state = egoState(x, y, yaw, speed)
state = struct('x', x, 'y', y, 'yaw', yaw, 'speed', speed, ...
    'Position', [x y 0], 'Velocity', [speed*cos(yaw) speed*sin(yaw) 0]);
end
