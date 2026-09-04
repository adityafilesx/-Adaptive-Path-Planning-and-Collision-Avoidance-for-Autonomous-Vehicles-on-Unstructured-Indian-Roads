function scenario = createCattleCrossingScenario(config)
%CREATECATTLECROSSINGSCENARIO Cattle moves continuously into the ego route.

    if nargin < 1, config = feval('config'); end
    ego = egoState(0, 0, 0, 0);
    actors(1) = makePhase8Actor(701, 'cattle', [70 16], [0 -2.0], ...
        [2.4 1.0], 'Crossing cattle');
    scenario = makePhase8Scenario('Sudden Cattle Crossing', ...
        'Cattle approaches from outside the route and creates a sharp crossing risk.', ...
        ego, [95 0 0], actors, 24, ...
        'Strong ACARG response, safe bypass or stop, then completion', 805, config);
    scenario.config.control.baseSpeed = 7.5;
    scenario.config.occupancy.worldLimits(2, :) = [-50 30];
end

function state = egoState(x, y, yaw, speed)
state = struct('x', x, 'y', y, 'yaw', yaw, 'speed', speed, ...
    'Position', [x y 0], 'Velocity', [speed*cos(yaw) speed*sin(yaw) 0]);
end
