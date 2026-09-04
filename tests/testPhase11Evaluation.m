% testPhase11Evaluation.m
% Deterministic final-evaluation, ablation, provenance, and artifact tests.

projectRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
originalCfg=config();
evaluation=runPhase11Evaluation(originalCfg,struct('saveResults',true,'generateFigures',true));
t=evaluation.dataset.scenarioMetrics;b=evaluation.baseline.table;
a=evaluation.ablation;s=evaluation.statisticalSummary;files=evaluation.savedFiles;

tests={@() test1(evaluation),@() test2(evaluation),@() test3(evaluation), ...
    @() test4(t),@() test5(t),@() test6(t),@() test7(t),@() test8(t), ...
    @() test9(s),@() test10(s),@() test11(t,s),@() test12(t,s), ...
    @() test13(t),@() test14(originalCfg),@() test15(originalCfg), ...
    @() test16(evaluation),@() test17(b),@() test18(b),@() test19(b), ...
    @() test20(a),@() test21(a),@() test22(originalCfg,a),@() test23(a), ...
    @() test24(files),@() test25(files),@() test26(files),@() test27(files), ...
    @() test28(evaluation.riskTimeline),@() test29(files),@() test30(evaluation), ...
    @() test31(s),@() test32(originalCfg),@() test33(evaluation.robustness), ...
    @() test34(evaluation.dataset),@() test35(files)};
passed=0;failed=0;
for i=1:numel(tests)
    try
        tests{i}();passed=passed+1;
    catch info
        failed=failed+1;fprintf('PHASE 11 TEST %d FAILED: %s\n',i,info.message);
    end
end
phase11TestResult=struct('passed',passed,'failed',failed, ...
    'evaluationFile',files.evaluationMat,'runDirectory',files.runDirectory);
fprintf('testPhase11Evaluation: %d passed, %d failed.\n',passed,failed);
if failed>0,error('testPhase11Evaluation:Failures','One or more Phase 11 tests failed.');end

function test1(e)
assert(isstruct(e.dataset)&&height(e.dataset.scenarioMetrics)==5,'Current benchmark dataset is absent.');
end
function test2(e)
assert(e.provenance.benchmarkVersion=="POST_PHASE9_FIX"&& ...
    e.provenance.collisionRiskVersion=="PHASE9_TIME_WEIGHTED_DISTANCE_V1", ...
    'Post-Phase9 provenance is missing.');
end
function test3(e)
assert(contains(e.provenance.legacyStatus,'NOT_AUTHORITATIVE')&& ...
    ~contains(e.provenance.sourceResultFile,'phase8Benchmark_'), ...
    'Legacy Phase 8 evidence was used as authoritative data.');
end
function test4(t)
expected=["Unmarked Village Road","Unsignalized Urban Intersection", ...
    "Highway Slow-Vehicle Merge","Dense Mixed-Traffic Market","Sudden Cattle Crossing"];
assert(isequal(t.Scenario,expected.'),'Not all five main scenarios are included.');
end
function test5(t)
assert(all(ismember(t.OutcomeClass,["GOAL_REACHED","SAFE_TERMINATION","FAILURE"])), ...
    'A scenario outcome is unclassified.');
end
function test6(t)
values=[double(t.Collision);t.MinimumActorDistance;t.MinimumPredictedCPADistance; ...
    t.ActivePathUnsafeMovingFrames;t.FailedReplanUnsafeContinuationCount];
assert(all(isfinite(values)),'Safety metrics contain NaN/Inf.');
end
function test7(t)
values=[t.SimulationTime;t.DistanceTravelled;t.InitialPathLength;t.Replans; ...
    t.MeanSpeed;t.TimeStopped;t.RMSSteering];
assert(all(isfinite(values)),'Efficiency/smoothness metrics contain NaN/Inf.');
end
function test8(t)
has=t.PlannerInvocationCount>0;
assert(all(isfinite(t.MeanReplanningLatencyMs(has)))&&all(isfinite(t.P95ReplanningLatencyMs(has))), ...
    'Planner latency is not finite where calls exist.');
end
function test9(s)
assert(s.p95PlannerLatencyMs>=s.medianPlannerLatencyMs,'P95 latency is below median.');
end
function test10(s)
assert(s.maximumPlannerLatencyMs>=s.meanPlannerLatencyMs,'Maximum latency is below mean.');
end
function test11(t,s)
assert(abs(s.collisionFreeRate-mean(~t.Collision))<eps,'Collision-free rate is incorrect.');
end
function test12(t,s)
assert(abs(s.goalReachRate-mean(t.GoalReached))<eps,'Goal-reach rate is incorrect.');
end
function test13(t)
safe=t.SafeTermination;assert(any(safe)&&all(~t.GoalReached(safe)),'Safe termination counted as goal.');
end
function test14(cfg)
[~,m]=createEvaluationMode(cfg,'FIXED_MARGIN_BASELINE');assert(~m.usesAdaptiveEnvelope,'Baseline did not initialize.');
end
function test15(cfg)
[full,m]=createEvaluationMode(cfg,'FULL_ACARG');assert(m.usesAdaptiveEnvelope&&isequaln(full,cfg),'Full ACARG mode changed configuration.');
end
function test16(e)
for i=1:numel(e.baseline.pairs)
    p=e.baseline.pairs{i};assert(isequaln(p.fullRun.scenario.actors,p.baselineScenario.actors)&& ...
        isequaln(p.fullRun.scenario.egoInitialState,p.baselineScenario.egoInitialState)&& ...
        isequaln(p.fullRun.scenario.goalPose,p.baselineScenario.goalPose), ...
        'Baseline and ACARG initial conditions differ.');
end
end
function test17(b)
q=b(b.Mode=="FIXED_MARGIN_BASELINE",:);assert(all(~q.UsesAdaptiveEnvelope)&& ...
    all(abs(q.MaximumAdaptiveEnvelopeScale-1)<1e-12),'Baseline uses adaptive inflation.');
end
function test18(b)
q=b(b.Mode=="FIXED_MARGIN_BASELINE",:);assert(all(q.CollisionCheckingRetained), ...
    'Baseline disabled collision checking.');
end
function test19(b)
q=b(b.Mode=="ACARG_ENHANCED",:);assert(any(q.MaximumAdaptiveEnvelopeScale>1), ...
    'ACARG envelope never differs from fixed margin.');
end
function test20(a)
f=a.confidence(a.confidence.Mode=="FULL_ACARG",:);n=a.confidence(a.confidence.Mode=="NO_CONFIDENCE_EFFECT",:);
assert(range(f.ActorRisk)>0.05&&range(n.ActorRisk)<1e-12,'Confidence ablation has no controlled effect.');
end
function test21(a)
f=a.cpa(a.cpa.Geometry=="Farther collision course"&a.cpa.Mode=="FULL_ACARG",:);
n=a.cpa(a.cpa.Geometry=="Farther collision course"&a.cpa.Mode=="NO_CPA_EFFECT",:);
assert(f.ActorRisk>n.ActorRisk,'CPA ablation did not change collision-course risk.');
end
function test22(cfg,a)
repeat=runACARGAblation(cfg);assert(isequaln(a.cpa,repeat.cpa),'Distance-only comparison is nondeterministic.');
end
function test23(a)
f=a.actorClass(a.actorClass.Mode=="FULL_ACARG",:);
assert(range(f.PhysicalDistance)<1e-12&&numel(unique(f.ActorClass))==3, ...
    'Actor-class experiment changed geometry.');
end
function test24(files),assert(isfile(files.headlineMetricsCsv),'Headline metrics CSV missing.');end
function test25(files),assert(isfile(files.scenarioMetricsCsv),'Scenario metrics CSV missing.');end
function test26(files),assert(isfile(files.ablationResultsCsv),'Ablation CSV missing.');end
function test27(files),assert(isfile(files.stateTransitionsCsv),'Transition CSV missing.');end
function test28(t)
assert(height(t)>0&&all(isfinite(t.Time))&&all(isfinite(t.TotalRisk))&& ...
    all(isfinite(t.DesiredSpeed))&&all(isfinite(t.ActualEgoSpeed)), ...
    'Risk/speed timeline timestamps are not aligned.');
end
function test29(files)
assert(numel(files.figureFiles)==18&&all(arrayfun(@isfile,files.figureFiles)), ...
    'Nine PNG/PDF figure pairs were not generated.');
end
function test30(e)
assert(all(arrayfun(@(r) all(isfinite(r.result.egoHistory(:))),e.dataset.scenarioRuns))&& ...
    all(e.baseline.table.FiniteRun),'A current evaluation scenario crashed or produced nonfinite state.');
end
function test31(s)
assert(all(isfinite(s.headlineMetrics.Value)),'Headline metrics contain NaN/Inf.');
end
function test32(cfg)
[~,~]=createEvaluationMode(cfg,'FIXED_MARGIN_BASELINE');assert(isequaln(cfg,config()), ...
    'Evaluation mode mutated frozen production configuration.');
end
function test33(r)
assert(height(r.summaryTable)==8&&r.aggregate.recoveredCount==8, ...
    'Phase 9 robustness results cannot be summarized.');
end
function test34(d)
assert(height(d.summaryTable)==5&&d.provenance.benchmarkVersion=="POST_PHASE9_FIX", ...
    'Corrected Phase 8 benchmark cannot be summarized.');
end
function test35(files)
output=evalc('r=mainPhase11(struct(''reuseLatest'',true));'); %#ok<NASGU>
assert(r.provenance.benchmarkVersion=="POST_PHASE9_FIX"&&isfile(files.evaluationMat), ...
    'mainPhase11 did not run end-to-end from saved evidence.');
end
