% testPhase9Robustness.m
% Deterministic Phase 9 robustness, recovery, and explainability tests.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
cfg = config();
scenarios = getPhase9StressScenarios(cfg);
robustness = runPhase9Robustness(cfg);
denseAudit = analyzeDenseMarketStop(cfg);
confidenceTable = runConfidenceSensitivity(cfg);
cpaTable = runCPASensitivity(cfg);

tests = {@() test1(robustness,cfg), @() test2(robustness), ...
    @() test3(robustness), @() test4(robustness), @() test5(robustness), ...
    @() test6(robustness), @() test7(robustness,cfg), ...
    @() test8(scenarios), @() test9(robustness), ...
    @() test10(confidenceTable), @() test11(robustness), ...
    @() test12(robustness), @() test13(robustness), ...
    @() test14(robustness), @() test15(robustness), ...
    @() test16(robustness), @() test17(robustness), ...
    @() test18(robustness), @() test19(robustness), ...
    @() test20(robustness), @() test21(robustness), ...
    @() test22(robustness), @() test23(robustness), ...
    @() test24(robustness), @() test25(robustness), ...
    @() test26(robustness), @() test27(robustness), ...
    @() test28(robustness), @() test29(robustness), ...
    @() test30(denseAudit), @() test31(denseAudit,cfg), ...
    @() test32(confidenceTable), @() test33(cpaTable), ...
    @() test34(cfg), @() test35(cfg)};

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
fprintf('testPhase9Robustness: %d passed, %d failed.\n', passed, failed);
if failed > 0
    error('testPhase9Robustness:Failures', 'One or more Phase 9 tests failed.');
end

function test1(b,cfg)
f = firstTransition(b);
e = explainACARGDecision(f,cfg);
assert(isstruct(e) && all(isfield(e, {'reason','actor','threshold','totalRisk'})), ...
    'Explainability structure is incomplete.');
end
function test2(b)
a = anyActor(b);
assert(isfield(a,'ActorID') && isfinite(a.ActorID), 'ActorID is absent.');
end
function test3(b)
a = allActors(b);
values = [[a.uncertaintyContribution] [a.confidenceContribution] ...
    [a.distanceContribution] [a.collisionContribution] [a.rawRisk] [a.risk]];
assert(all(isfinite(values)), 'A risk component is NaN/Inf.');
end
function test4(b)
a = allActors(b);
cpa = [a.collisionDiagnostics];
assert(all(~isnan([cpa.cpaTime])) && all(~isnan([cpa.cpaDistance])), ...
    'CPA diagnostics contain NaN.');
end
function test5(b)
for r = 1:numel(b.scenarioRuns)
    log = b.scenarioRuns(r).detail.result.log;
    for i = 1:5:numel(log)
        risks = [log(i).actorRiskDetails.risk];
        [value,index] = max(risks);
        assert(log(i).acargDiagnostics.dominantActorID == ...
            log(i).actorRiskDetails(index).ActorID && ...
            abs(log(i).acargDiagnostics.dominantActorRisk-value)<1e-12, ...
            'Dominant actor does not match maximum actor risk.');
    end
end
end
function test6(b)
for r = 1:numel(b.scenarioRuns)
    e = b.scenarioRuns(r).detail.transitionExplanations;
    for i = 1:numel(e)
        assert(e(i).stateChanged && ...
            e(i).previousGovernorState ~= e(i).finalGovernorState, ...
            'Transition explanation does not match the logged transition.');
    end
end
end
function test7(b,cfg)
f = b.scenarioRuns(1).detail.result.log(1);
assert(isequaln(f.acargDiagnostics.thresholds,cfg.governor.thresholds), ...
    'Configured thresholds were not logged exactly.');
end
function test8(s)
assert(numel(s)==8 && all(cellfun(@(x) validatePhase9Scenario(x).valid,s)), ...
    'A stress scenario failed initialization.');
end
function test9(b)
r = namedRun(b,'Confidence Drop').detail.result.log;
before = actorAt(r,801,3.8); during = actorAt(r,801,5.0); after = actorAt(r,801,7.4);
assert(during.confidence < before.confidence && after.confidence > during.confidence && ...
    during.uncertainty > before.uncertainty, ...
    'Confidence drop did not affect trust/uncertainty appropriately.');
end
function test10(t)
assert(all(diff(t.ActorRisk)>0) && all(diff(t.Uncertainty)>0), ...
    'Lower confidence did not monotonically increase current-formulation risk.');
end
function test11(b)
r = namedRun(b,'Temporary Detection Loss').detail.result;
assert(~r.collisionOccurred && any([r.log.detectionCount]==0), ...
    'Temporary detection loss crashed or was not injected.');
end
function test12(b)
r = namedRun(b,'Temporary Detection Loss').detail.result.log;
post = r([r.time]>5.0);
assert(any([post.detectionCount]>0) && all(arrayfun(@uniqueTrackIDs,r)), ...
    'Actor reappearance was not deterministic or duplicated its ID.');
end
function test13(b)
r = namedRun(b,'Sudden Direction Reversal').detail.result.log;
vy = arrayfun(@(x) actorTruthVelocity(x,803),r);
assert(any(vy>0) && any(vy<0), 'Direction reversal did not change truth velocity.');
end
function test14(b)
r = namedRun(b,'Sudden Direction Reversal').detail.result.log;
a = arrayfun(@(x) actorRiskValue(x,803),r);
c = arrayfun(@(x) actorCPAValue(x,803),r);
assert(range(a)>0.15 && range(c)>1, 'Direction reversal did not change CPA/risk.');
end
function test15(b)
r = namedRun(b,'Multiple Simultaneous Risks').detail.result.log;
assert(all(arrayfun(@(x) numel(unique([x.actorRiskDetails.ActorID]))==2,r)), ...
    'Multiple actors lost unique IDs.');
end
function test16(b)
r = namedRun(b,'Multiple Simultaneous Risks');
assert(r.summary.DominantActorChanges>0, 'Dominant actor never changed.');
end
function test17(b)
e = namedRun(b,'Temporary Path Obstruction').detail.result.planEvents;
assert(any(arrayfun(@(x) hasReason(x,'Upcoming active path is unsafe.'),e)), ...
    'Temporary obstruction did not trigger path-safety replanning.');
end
function test18(b)
assert(all(b.summaryTable.ActivePathUnsafeMovingFrames==0), ...
    'A scenario commanded forward motion while its active path was unsafe.');
end
function test19(b)
e = namedRun(b,'Replan Failure Recovery').detail.result.planEvents;
safeFailure = arrayfun(@(x) ~x.success && x.oldLength>0 && ...
    ~hasReason(x,'Upcoming active path is unsafe.'),e);
assert(any(safeFailure), 'Failed replan never retained a still-safe old path.');
end
function test20(b)
r = namedRun(b,'Replan Failure Recovery').detail.result;
unsafeFailure = arrayfun(@(x) ~x.success && ...
    hasReason(x,'Upcoming active path is unsafe.'),r.planEvents);
assert(any(unsafeFailure), 'No unsafe-old-path planning failure was exercised.');
times = [r.planEvents(unsafeFailure).time];
stopped = arrayfun(@(t) r.log(find(abs([r.log.time]-t)<1e-9,1)).desiredSpeed==0,times);
assert(all(stopped), 'Unsafe failed replan did not command zero desired speed.');
end
function test21(b)
r = namedRun(b,'Replan Failure Recovery');
assert(r.summary.RecoveryOccurred && r.summary.GoalReached, ...
    'Planning did not recover when geometry cleared.');
end
function test22(b)
r = namedRun(b,'Conservative Stop Recovery').detail.result.log;
stop = strcmp({r.acargState},'CONSERVATIVE_STOP');
first = find(stop,1);
assert(~isempty(first) && min([r(stop).egoSpeed]) < [r(first).egoSpeed] && ...
    min([r(stop).egoSpeed]) < 0.1, 'CONSERVATIVE_STOP did not physically stop ego.');
end
function test23(b)
r = namedRun(b,'Conservative Stop Recovery').detail.result.log;
stop = strcmp({r.acargState},'CONSERVATIVE_STOP');
assert(any([false stop(1:end-1)] & ~stop), 'System never exited CONSERVATIVE_STOP.');
end
function test24(b)
r = namedRun(b,'Conservative Stop Recovery').detail.result.log;
stop = strcmp({r.acargState},'CONSERVATIVE_STOP');
exitIndex = find([false stop(1:end-1)] & ~stop,1);
assert(any([r(exitIndex:end).egoSpeed]>0.2), 'Vehicle did not resume after STOP exit.');
end
function test25(b)
r = namedRun(b,'Rapid Risk Fluctuation').summary;
assert(r.StateTransitions<=6 && (isnan(r.MinimumTransitionInterval) || ...
    r.MinimumTransitionInterval>=0.8), 'Governor exhibited excessive chatter.');
end
function test26(b)
assert(all(b.summaryTable.FiniteOutputs), 'A run contains NaN/Inf ego output.');
end
function test27(b)
for r=1:numel(b.scenarioRuns)
    log=b.scenarioRuns(r).detail.result.log;
    assert(all(isfinite([log.totalRisk])) && all(~cellfun(@isempty,{log.acargState})), ...
        'A run contains invalid ACARG output.');
end
end
function test28(b)
assert(all(~b.summaryTable.Collision), 'A main robustness run collided.');
end
function test29(b)
assert(all(b.summaryTable.ActivePathUnsafeMovingFrames==0), ...
    'Knowingly unsafe forward progress occurred.');
end
function test30(a)
assert(contains(a.classification,'Genuine implementation defect') && ...
    strlength(a.defectCause)>20 && ...
    all(isfinite([a.transition.CombinedAdaptiveScale ...
        a.transition.EffectiveSafetyExtentX a.transition.EffectiveSafetyExtentY])), ...
    'Dense Market STOP lacks cause or adaptive-envelope evidence.');
end
function test31(a,cfg)
assert(abs(a.transition.TotalRisk-0.701145)<1e-5 && ...
    abs(a.transition.RelevantThreshold-cfg.governor.thresholds.conservativeEnter)<eps && ...
    a.transition.TotalRisk>=a.transition.RelevantThreshold, ...
    'Dense Market transition does not match threshold logic.');
end
function test32(t)
assert(height(t)==4 && all(isfinite(t.ActorRisk)), ...
    'Confidence sensitivity table was not generated.');
end
function test33(t)
assert(t.PhysicalDistance(1)<t.PhysicalDistance(2) && ...
    t.CPADistance(1)>t.CPADistance(2) && t.ActorRisk(1)<t.ActorRisk(2), ...
    'CPA comparison did not demonstrate geometry-dependent risk.');
end
function test34(cfg)
b=runPhase8Benchmark(cfg,struct('saveResults',false,'generatePlots',false));
assert(height(b.summaryTable)==5 && all(~b.summaryTable.Collision), ...
    'Phase 8 benchmark no longer executes safely.');
end
function test35(cfg)
d=createPhase7Demo(cfg); d.config.control.enableVisualization=false;
r=runClosedLoopSimulation(d);
assert(r.goalReached && ~r.collisionOccurred, 'Phase 7 demo regressed.');
end

function frame=firstTransition(b)
for i=1:numel(b.scenarioRuns)
    idx=b.scenarioRuns(i).detail.transitionIndices;
    if ~isempty(idx), frame=b.scenarioRuns(i).detail.result.log(idx(1)); return; end
end
error('No transition found.');
end
function actor=anyActor(b)
actor=b.scenarioRuns(1).detail.result.log(1).actorRiskDetails(1);
end
function actors=allActors(b)
actors=struct([]);
for i=1:numel(b.scenarioRuns)
    log=b.scenarioRuns(i).detail.result.log;
    for j=1:numel(log), actors=[actors;log(j).actorRiskDetails(:)]; end %#ok<AGROW>
end
end
function run=namedRun(b,name)
run=b.scenarioRuns(strcmp({b.scenarioRuns.scenarioName},name));
end
function actor=actorAt(log,id,time)
[~,i]=min(abs([log.time]-time)); actor=log(i).actorRiskDetails([log(i).actorRiskDetails.ActorID]==id);
end
function ok=uniqueTrackIDs(frame)
ids=[frame.tracks.ActorID]; ok=numel(ids)==numel(unique(ids));
end
function value=actorTruthVelocity(frame,id)
a=frame.actorTruth([frame.actorTruth.ID]==id); value=a.Velocity(2);
end
function value=actorRiskValue(frame,id)
a=frame.actorRiskDetails([frame.actorRiskDetails.ActorID]==id); value=a.risk;
end
function value=actorCPAValue(frame,id)
a=frame.actorRiskDetails([frame.actorRiskDetails.ActorID]==id); value=a.collisionDiagnostics.cpaDistance;
end
function value=hasReason(event,text)
value=any(strcmp(event.reasons,text));
end
