function scenario = createDenseMarketScenario(config)
%CREATEDENSEMARKETSCENARIO Heterogeneous moderate-risk market traffic.

    if nargin < 1, config = feval('config'); end
    ego = egoState(0, 0, 0, 0);
    actors(1) = makePhase8Actor(601, 'pedestrian', [65 18], [0 -2.0], ...
        [0.6 0.6], 'Market pedestrian');
    actors(2) = makePhase8Actor(602, 'car', [100 -18], [0 2.0], ...
        [4.7 1.8], 'Slow market car');
    scenario = makePhase8Scenario('Dense Mixed-Traffic Market', ...
        'Pedestrian and slow-car traffic generate simultaneous heterogeneous risks.', ...
        ego, [90 0 0], actors, 34, ...
        'Sustained caution, repeated evaluation, and safe completion', 804, config);
    scenario.config.control.baseSpeed = 5.0;
    scenario.config.occupancy.worldLimits(2, :) = [-50 50];
end

function state = egoState(x, y, yaw, speed)
state = struct('x', x, 'y', y, 'yaw', yaw, 'speed', speed, ...
    'Position', [x y 0], 'Velocity', [speed*cos(yaw) speed*sin(yaw) 0]);
end
