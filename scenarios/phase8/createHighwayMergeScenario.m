function scenario = createHighwayMergeScenario(config)
%CREATEHIGHWAYMERGESCENARIO Slow lead vehicle with a lateral merge conflict.

    if nargin < 1, config = feval('config'); end
    ego = egoState(0, 0, 0, 0);
    actors(1) = makePhase8Actor(501, 'car', [42 7], [1 0], ...
        [4.7 1.8], 'Slow lead vehicle');
    actors(2) = makePhase8Actor(502, 'car', [32 -14], [2 0.3], ...
        [4.7 1.8], 'Merging vehicle');
    scenario = makePhase8Scenario('Highway Slow-Vehicle Merge', ...
        'A slow lead vehicle and moving lateral constraint create a merge conflict.', ...
        ego, [90 0 0], actors, 24, ...
        'Reduced speed and safe modified pass', 803, config);
    scenario.config.control.baseSpeed = 7.5;
end

function state = egoState(x, y, yaw, speed)
state = struct('x', x, 'y', y, 'yaw', yaw, 'speed', speed, ...
    'Position', [x y 0], 'Velocity', [speed*cos(yaw) speed*sin(yaw) 0]);
end
