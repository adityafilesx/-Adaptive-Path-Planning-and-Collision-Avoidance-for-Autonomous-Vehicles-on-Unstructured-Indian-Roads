% testPhase8Scenarios.m
% Deterministic validation of Phase 8 scenario and benchmark infrastructure.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
cfg = config();
scenarios = getPhase8Scenarios(cfg);
benchmark = runPhase8Benchmark(cfg, ...
    struct('saveResults', false, 'generatePlots', false));

tests = {@() assert(numel(scenarios) == 5, 'Five scenarios are required.'), ...
    @() testUniqueNames(scenarios), ...
    @() testEgoStates(scenarios), ...
    @() testGoals(scenarios), ...
    @() testActorsPresent(scenarios), ...
    @() testActorsFinite(scenarios), ...
    @() testNoInitialCollision(scenarios), ...
    @() testCommonSchema(scenarios), ...
    @() testSanity(benchmark, 1), ...
    @() testSanity(benchmark, 2), ...
    @() testSanity(benchmark, 3), ...
    @() testSanity(benchmark, 4), ...
    @() testSanity(benchmark, 5), ...
    @() assert(numel(benchmark.scenarioRuns) == 5, 'Batch runner omitted scenarios.'), ...
    @() testStructuredResults(benchmark), ...
    @() testFiniteSimulationTime(benchmark), ...
    @() testReplanCounts(benchmark), ...
    @() testLatencyMeasured(benchmark), ...
    @() testStatesLogged(benchmark), ...
    @() testCautiousObserved(benchmark), ...
    @() testPathChanged(benchmark), ...
    @() testMultipleClasses(scenarios), ...
    @() testSuccessfulCollisionFree(benchmark), ...
    @() testUnsafeMovingFrames(benchmark), ...
    @() testCompletionRate(benchmark), ...
    @() testCollisionFreeRate(benchmark), ...
    @() assert(height(benchmark.summaryTable) == 5, ...
        'Summary table must contain all scenarios.'), ...
    @() testSave(benchmark), ...
    @() testPhase7StillRuns(cfg), ...
    @() testNoUnexplainedFailure(benchmark)};

passed = 0;
failed = 0;
for i = 1:numel(tests)
    try
        tests{i}();
        passed = passed + 1;
    catch errorInfo
        failed = failed + 1;
        fprintf('TEST %d FAILED: %s\n', i, errorInfo.message);
    end
end
fprintf('testPhase8Scenarios: %d passed, %d failed.\n', passed, failed);
if failed > 0
    error('testPhase8Scenarios:Failures', 'One or more Phase 8 tests failed.');
end

function testUniqueNames(scenarios)
names = cellfun(@(s) s.name, scenarios, 'UniformOutput', false);
assert(numel(unique(names)) == numel(names), 'Scenario names must be unique.');
end

function testEgoStates(scenarios)
for i = 1:numel(scenarios)
    e = scenarios{i}.egoInitialState;
    assert(all(isfinite([e.x e.y e.yaw e.speed])), 'Invalid ego initial state.');
end
end

function testGoals(scenarios)
for i = 1:numel(scenarios)
    assert(numel(scenarios{i}.goalPose) == 3 && ...
        all(isfinite(scenarios{i}.goalPose)), 'Invalid scenario goal.');
end
end

function testActorsPresent(scenarios)
assert(all(cellfun(@(s) ~isempty(s.actors), scenarios)), ...
    'Every scenario must contain actors.');
end

function testActorsFinite(scenarios)
for i = 1:numel(scenarios)
    assert(all(isfinite([scenarios{i}.actors.Position])) && ...
        all(isfinite([scenarios{i}.actors.Velocity])), 'Actor state is not finite.');
end
end

function testNoInitialCollision(scenarios)
for i = 1:numel(scenarios)
    collision = checkCollision(scenarios{i}.egoState, ...
        scenarios{i}.actors, scenarios{i}.config);
    assert(~collision, 'Scenario begins in collision.');
end
end

function testCommonSchema(scenarios)
required = {'name','description','egoInitialState','egoState','goalPose', ...
    'actors','maxSimulationTime','expectedBehavior','seed','config'};
for i = 1:numel(scenarios)
    assert(all(isfield(scenarios{i}, required)), 'Common schema is incomplete.');
end
end

function testSanity(benchmark, index)
assert(benchmark.scenarioRuns(index).sanity.valid, ...
    'Scenario sanity validation failed.');
end

function testStructuredResults(benchmark)
assert(all(arrayfun(@(r) isstruct(r.result) && isfield(r.result, 'metrics'), ...
    benchmark.scenarioRuns)), 'A benchmark result is not structured.');
end

function testFiniteSimulationTime(benchmark)
assert(all(isfinite(benchmark.summaryTable.SimulationTime)), ...
    'Simulation time must be finite.');
end

function testReplanCounts(benchmark)
assert(all(benchmark.summaryTable.Replans >= 0), 'Replan count must be nonnegative.');
end

function testLatencyMeasured(benchmark)
for i = 1:numel(benchmark.scenarioRuns)
    events = benchmark.scenarioRuns(i).result.planEvents;
    if ~isempty(events)
        assert(all([events.latencySeconds] > 0), ...
            'Planner wall-clock latency was not measured.');
    end
end
end

function testStatesLogged(benchmark)
assert(all(arrayfun(@(r) ~isempty(r.result.log) && ...
    all(~cellfun(@isempty, {r.result.log.acargState})), benchmark.scenarioRuns)), ...
    'ACARG states must be logged.');
end

function testCautiousObserved(benchmark)
observed = arrayfun(@(r) any(strcmp({r.result.log.acargState}, 'CAUTIOUS')), ...
    benchmark.scenarioRuns);
assert(any(observed), 'At least one scenario must observe CAUTIOUS.');
end

function testPathChanged(benchmark)
assert(any(benchmark.summaryTable.PathChangeCount > 0), ...
    'At least one scenario must replace its path.');
end

function testMultipleClasses(scenarios)
hasMixed = cellfun(@(s) numel(unique({s.actors.TrueClass})) > 1, scenarios);
assert(any(hasMixed), 'At least one scenario must contain multiple actor classes.');
end

function testSuccessfulCollisionFree(benchmark)
successful = benchmark.summaryTable.GoalReached;
assert(all(~benchmark.summaryTable.Collision(successful)), ...
    'A successful scenario contains a collision.');
end

function testUnsafeMovingFrames(benchmark)
successful = benchmark.summaryTable.GoalReached;
assert(all(benchmark.summaryTable.UnsafeMovingFrames(successful) == 0), ...
    'A successful scenario moved while its path was unsafe.');
end

function testCompletionRate(benchmark)
expected = sum(benchmark.summaryTable.ScenarioCompleted) / ...
    height(benchmark.summaryTable);
assert(abs(benchmark.aggregate.completionRate - expected) < eps, ...
    'Completion rate is incorrect.');
end

function testCollisionFreeRate(benchmark)
expected = sum(~benchmark.summaryTable.Collision) / height(benchmark.summaryTable);
assert(abs(benchmark.aggregate.collisionFreeRate - expected) < eps, ...
    'Collision-free rate is incorrect.');
end

function testSave(benchmark)
directory = tempname;
files = savePhase8Benchmark(benchmark, directory);
assert(isfile(files.benchmarkMat) && isfile(files.summaryCsv) && ...
    isfile(files.aggregateMat), 'Benchmark result files were not saved.');
end

function testPhase7StillRuns(cfg)
demo = createPhase7Demo(cfg);
demo.config.control.enableVisualization = false;
result = runClosedLoopSimulation(demo);
assert(result.goalReached && ~result.collisionOccurred, ...
    'Phase 7 demo no longer completes safely.');
end

function testNoUnexplainedFailure(benchmark)
explained = benchmark.summaryTable.GoalReached | benchmark.summaryTable.SafeTermination;
assert(all(explained) && all(strlength(benchmark.summaryTable.TerminationReason) > 0), ...
    'Benchmark contains an unexplained runtime failure.');
end
