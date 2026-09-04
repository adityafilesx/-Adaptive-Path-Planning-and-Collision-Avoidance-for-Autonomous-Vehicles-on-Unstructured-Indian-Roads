% testClosedLoop.m
% Deterministic Phase 7 vehicle-control and closed-loop integration tests.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
cfg = config();
cfg.control.enableVisualization = false;
passed = 0;
failed = 0;

tests = {@() test1(cfg), @() test2(cfg), @() test3(cfg), @() test4(cfg), ...
    @() test5(cfg), @() test6(cfg), @() test7(cfg), @() test8(cfg), ...
    @() test9(cfg), @() test10(cfg), @() test11(cfg), @() test12(cfg), ...
    @() test13(cfg), @() test14(cfg), @() test15(cfg), @() test16(cfg), ...
    @() test17(cfg), @() test18(cfg)};
for i = 1:numel(tests)
    try
        tests{i}();
        passed = passed + 1;
    catch errorInfo
        failed = failed + 1;
        fprintf('TEST %d FAILED: %s\n', i, errorInfo.message);
    end
end

closedLoopResult = [];
try
    demo = createPhase7Demo(cfg);
    demo.config.control.enableVisualization = false;
    closedLoopResult = runClosedLoopSimulation(demo);
catch errorInfo
    fprintf('PHASE 7 INTEGRATION SETUP FAILED: %s\n', errorInfo.message);
end
integrationTests = {@() test19(closedLoopResult), ...
    @() test20(closedLoopResult), @() test21(closedLoopResult), ...
    @() test22(closedLoopResult), @() test23(closedLoopResult), ...
    @() test24(closedLoopResult), @() test25(closedLoopResult)};
for i = 1:numel(integrationTests)
    testNumber = i + 18;
    try
        integrationTests{i}();
        passed = passed + 1;
    catch errorInfo
        failed = failed + 1;
        fprintf('TEST %d FAILED: %s\n', testNumber, errorInfo.message);
    end
end

fprintf('testClosedLoop: %d passed, %d failed.\n', passed, failed);
if failed > 0
    error('testClosedLoop:Failures', 'One or more Phase 7 tests failed.');
end

function state = baseState(speed)
state = struct('x', 0, 'y', 0, 'yaw', 0, 'speed', speed, ...
    'Position', [0 0 0], 'Velocity', [speed 0 0]);
end

function test1(cfg)
s = kinematicBicycleStep(baseState(2), 0, 0, cfg);
assert(s.x > 0, 'Ego state must propagate forward.');
end

function test2(cfg)
s = kinematicBicycleStep(baseState(0), 0, 0, cfg);
assert(abs(s.x) < eps && abs(s.y) < eps, ...
    'Zero speed must produce no translation.');
end

function test3(cfg)
s = kinematicBicycleStep(baseState(2), 0, 0, cfg);
assert(abs(s.y) < 1e-12 && abs(s.yaw) < 1e-12, ...
    'Zero steering must produce straight motion.');
end

function test4(cfg)
s = kinematicBicycleStep(baseState(2), 0.2, 0, cfg);
assert(s.yaw > 0, 'Positive steering must increase yaw.');
end

function test5(cfg)
[~, applied] = kinematicBicycleStep(baseState(2), 10, 0, cfg);
assert(abs(applied.steering) <= cfg.control.maxSteering + eps, ...
    'Steering limit was not enforced.');
end

function test6(cfg)
s = kinematicBicycleStep(baseState(1), 0, 100, cfg);
expected = 1 + cfg.control.maxAcceleration * cfg.control.dt;
assert(abs(s.speed - expected) < 1e-12, ...
    'Maximum acceleration was not enforced.');
end

function test7(cfg)
s = kinematicBicycleStep(baseState(5), 0, -100, cfg);
expected = 5 - cfg.control.maxDeceleration * cfg.control.dt;
assert(abs(s.speed - expected) < 1e-12, ...
    'Maximum deceleration was not enforced.');
end

function test8(cfg)
s = kinematicBicycleStep(baseState(0.1), 0, -100, cfg);
assert(s.speed == 0, 'Forward-only speed must not become negative.');
end

function test9(cfg)
path = struct('success', true, 'states', [0 0 0; 5 1 0; 10 1 0]);
steering = followPath(baseState(2), path, cfg);
assert(isfinite(steering) && abs(steering) <= cfg.control.maxSteering, ...
    'Path follower must return finite bounded steering.');
end

function test10(cfg)
[reached, ~] = checkGoalReached(baseState(0), [0.5 0 0], cfg);
assert(reached, 'Goal detection must accept a pose inside tolerance.');
end

function test11(cfg)
[reached, ~] = checkGoalReached(baseState(0), [2 0 0], cfg);
assert(~reached, 'Goal detection must reject a pose outside tolerance.');
end

function test12(cfg)
a = acargStub('NORMAL', cfg.governor.speedScale.NORMAL, false);
assert(desiredSpeedForACARG(a, cfg) == cfg.control.baseSpeed, ...
    'NORMAL must command nominal speed.');
end

function test13(cfg)
n = desiredSpeedForACARG(acargStub('NORMAL', 1, false), cfg);
c = desiredSpeedForACARG(acargStub('CAUTIOUS', ...
    cfg.governor.speedScale.CAUTIOUS, false), cfg);
assert(c < n, 'CAUTIOUS speed must be lower than NORMAL speed.');
end

function test14(cfg)
a = acargStub('CONSERVATIVE_STOP', ...
    cfg.governor.speedScale.CONSERVATIVE_STOP, true);
assert(desiredSpeedForACARG(a, cfg) == 0, ...
    'CONSERVATIVE_STOP must command a stop.');
end

function test15(cfg)
s = baseState(3);
n = updateEgoState(s, 0, cfg.control.baseSpeed, cfg);
c = updateEgoState(s, 0, ...
    cfg.control.baseSpeed * cfg.governor.speedScale.CAUTIOUS, cfg);
assert(n.speed > c.speed, ...
    'ACARG speed scale must affect physical speed evolution.');
end

function test16(cfg)
[path, planner] = freePath(cfg);
a = acargStub('CAUTIOUS', cfg.governor.speedScale.CAUTIOUS, true);
[required, reasons] = shouldReplan(path, planner, [0 0 0], 0, 1, ...
    a, a, cfg);
assert(required && any(strcmp(reasons, 'ACARG requested replanning.')), ...
    'ACARG replanRequested must trigger the policy.');
end

function test17(cfg)
[path, planner] = freePath(cfg);
a = acargStub('NORMAL', 1, false);
required = shouldReplan(path, planner, [0 0 0], 0, 0.2, a, a, cfg);
assert(~required, 'Stable safe conditions must not replan before the interval.');
end

function test18(cfg)
[path, ~] = freePath(cfg);
blockedCfg = cfg;
blockedCfg.prediction.horizon = 0;
blockedCfg.control.pathSafetyHorizon = 40;
track = makeTrack(901, 'car', [10 0], [0 0], blockedCfg);
map = updateOccupancyMap(track, baseState(0), blockedCfg);
planner = createPlanner(map, blockedCfg);
a = acargStub('NORMAL', 1, false);
[required, reasons] = shouldReplan(path, planner, [0 0 0], 0, 0.2, ...
    a, a, blockedCfg);
assert(required && any(strcmp(reasons, 'Upcoming active path is unsafe.')), ...
    'An invalidated active path must trigger replanning.');
end

function test19(result)
assert(~isempty(result) && any([result.planEvents.pathReplaced]), ...
    'A newly generated path must replace the previous path.');
end

function test20(result)
assert(norm(result.egoHistory(end, 1:2) - result.egoHistory(1, 1:2)) > 1, ...
    'Closed-loop ego pose must change across frames.');
end

function test21(result)
assert(abs(result.actorHistory(1, 2, end) - ...
    result.actorHistory(1, 2, 1)) > 1, ...
    'Dynamic actor position must change across frames.');
end

function test22(result)
assert(range([result.log.totalRisk]) > 1e-3, ...
    'Risk must be recomputed rather than held constant.');
end

function test23(result)
states = {result.log.acargState};
assert(any(~strcmp(states(2:end), states(1:end-1))), ...
    'The deterministic demo must produce a governor transition.');
end

function test24(result)
assert(~isempty(result) && ~isempty(result.log), ...
    'Closed-loop demo must finish without runtime errors.');
end

function test25(result)
validSafeReason = strcmp(result.terminationReason, ...
    'Safely stopped after repeated planning failures.');
assert((result.goalReached && ~result.collisionOccurred) || validSafeReason, ...
    'Demo must reach the goal or report an explicit valid safety stop.');
end

function [path, planner] = freePath(cfg)
map = updateOccupancyMap(struct([]), baseState(0), cfg);
planner = createPlanner(map, cfg);
path = planPath(planner, [0 0 0], [40 0 0], cfg);
end

function track = makeTrack(id, actorClass, position, velocity, cfg)
d = struct('ID', id, 'Position', [position 0], 'Velocity', [velocity 0], ...
    'PerceivedClass', actorClass, 'TrueClass', actorClass, ...
    'PositionStd', [0.1 0.1 0.1], 'VelocityStd', [0.1 0.1 0.1], ...
    'IsDetected', true, 'Confidence', 0.95);
track = initializeTracker(d, cfg.control.dt, cfg, 0);
end

function a = acargStub(state, speedScale, replanRequested)
a = struct('state', state, 'speedScale', speedScale, ...
    'replanRequested', replanRequested, ...
    'risk', struct('totalRisk', 0.2));
end
