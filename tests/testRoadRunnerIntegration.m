% testRoadRunnerIntegration.m
% Phase 10 platform-independent architecture and conditional runtime tests.

projectRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
cfg=config();
keys=["village","urban","highway","denseMarket","cattle"];
manifests=cellfun(@(k) loadRoadRunnerManifest(k,cfg),cellstr(keys),'UniformOutput',false);
architecture=validateRoadRunnerArchitecture(cfg);

staticTests={@() test1(cfg),@() test2(cfg),@() test3(cfg), ...
    @() test4(cfg),@() test5(manifests),@() test6(manifests), ...
    @() test7(cfg),@() test8(cfg),@() test9(manifests), ...
    @() test10(manifests),@() test11(manifests),@() test12(cfg), ...
    @() test13(cfg),@() test14(cfg),@() test15(cfg),@() test16(cfg), ...
    @() test17(cfg),@() test18(),@() test19(),@() test20(cfg), ...
    @() test21(cfg),@() test22(cfg),@() test23(cfg),@() test24(cfg), ...
    @() test25(cfg),@() test26(cfg),@() test27(cfg),@() test28(architecture)};

staticPassed=0; staticFailed=0;
for i=1:numel(staticTests)
    try
        staticTests{i}(); staticPassed=staticPassed+1;
    catch info
        staticFailed=staticFailed+1;
        fprintf('STATIC TEST %d FAILED: %s\n',i,info.message);
    end
end

runtimeCfg=applyRoadRunnerLocalConfiguration(config());
capability=isRoadRunnerAvailable(runtimeCfg);
runtimePassed=0; runtimeFailed=0; runtimeSkipped=0;
if capability.available
    runtimeCfg.roadrunner.enabled=true;
    villageRun=runRoadRunnerBridge(runtimeCfg,'village');
    urbanRun=runRoadRunnerBridge(runtimeCfg,'urban');
    runtimeTests={@() test29(villageRun),@() test30(villageRun), ...
        @() test31(urbanRun),@() test32(villageRun),@() test33(villageRun), ...
        @() test34(villageRun),@() test35(villageRun),@() test36(villageRun,runtimeCfg), ...
        @() test37(villageRun),@() test38(urbanRun),@() test39(villageRun), ...
        @() test40(villageRun,urbanRun)};
    for i=1:numel(runtimeTests)
        try
            runtimeTests{i}(); runtimePassed=runtimePassed+1;
        catch info
            runtimeFailed=runtimeFailed+1;
            fprintf('RUNTIME TEST %d FAILED: %s\n',i+28,info.message);
        end
    end
else
    runtimeSkipped=12;
end

phase10TestResult=struct('platformIndependentPassed',staticPassed, ...
    'platformIndependentFailed',staticFailed,'runtimePassed',runtimePassed, ...
    'runtimeFailed',runtimeFailed,'runtimeSkipped',runtimeSkipped, ...
    'capability',capability);
fprintf('testRoadRunnerIntegration platform-independent: %d PASS, %d FAIL.\n', ...
    staticPassed,staticFailed);
fprintf('testRoadRunnerIntegration runtime: %d PASS, %d FAIL, %d SKIPPED.\n', ...
    runtimePassed,runtimeFailed,runtimeSkipped);
if runtimeSkipped>0, fprintf('Runtime skip reason: %s\n',capability.reason); end
if staticFailed>0 || runtimeFailed>0
    error('testRoadRunnerIntegration:Failures','One or more Phase 10 tests failed.');
end

function test1(cfg)
c=isRoadRunnerAvailable(cfg);
assert(all(isfield(c,{'available','platformSupported','matlabAPIFound', ...
    'projectConfigured','reason'})),'Capability structure is incomplete.');
end
function test2(cfg)
c=isRoadRunnerAvailable(cfg);
if ismac, assert(~c.platformSupported && contains(c.reason,'macOS'), ...
    'macOS was not classified as unsupported.'); end
end
function test3(cfg)
cfg.roadrunner.projectRoot=''; c=isRoadRunnerAvailable(cfg);
assert(isstruct(c)&&~c.available,'Unavailable RoadRunner did not return cleanly.');
end
function test4(cfg)
p=getRoadRunnerPaths(cfg);
assert(p.manifestRoot==string(fullfile(p.roadRunnerRoot,'manifests')), ...
    'Repository-relative path construction is invalid.');
end
function test5(manifests)
for i=1:numel(manifests), assert(~contains(portableJSON(manifests{i}),'C:\\'), ...
    'Manifest contains a hard-coded Windows path.'); end
end
function test6(manifests)
for i=1:numel(manifests), assert(~contains(portableJSON(manifests{i}),'/Users/'), ...
    'Manifest contains a hard-coded macOS path.'); end
end
function test7(cfg)
m=loadRoadRunnerManifest('village',cfg);
assert(strcmp(m.scenarioName,'Unmarked Village Road'),'Village manifest did not load.');
end
function test8(cfg)
m=loadRoadRunnerManifest('urban',cfg);
assert(strcmp(m.scenarioName,'Unsignalized Urban Intersection'),'Urban manifest did not load.');
end
function test9(manifests)
for i=1:numel(manifests), ids=[manifests{i}.actors.logicalActorID]; ...
    assert(numel(ids)==numel(unique(ids)),'Duplicate logical ActorID.'); end
end
function test10(manifests)
for i=1:numel(manifests)
    for j=1:numel(manifests{i}.actors)
        [mapped,d]=mapRoadRunnerActorClass(manifests{i}.actors(j).canonicalClass);
        assert(~d.usedFallback && mapped==string(manifests{i}.actors(j).canonicalClass), ...
            'Unsupported canonical actor class.');
    end
end
end
function test11(manifests)
assert(all(cellfun(@(m) strlength(string(m.egoActorName))>0,manifests)), ...
    'A manifest does not identify the ego actor.');
end
function test12(cfg)
rr=canonicalPoseToRoadRunner([3 -2 0.4],cfg.roadrunner.coordinateTransform);
assert(all(isfinite([rr.Position rr.Velocity rr.Yaw rr.Pose(:).'])), ...
    'Canonical-to-RoadRunner conversion is not finite.');
end
function test13(cfg)
c=roadRunnerPoseToCanonical(canonicalPoseToRoadRunner([3 -2 0.4], ...
    cfg.roadrunner.coordinateTransform),cfg.roadrunner.coordinateTransform);
assert(all(isfinite([c.Position c.Velocity c.yaw])),'RoadRunner-to-canonical output is not finite.');
end
function test14(cfg)
[a,b]=roundTripSample(cfg); assert(abs(a.Position(1)-b.Position(1))<1e-12,'X did not round-trip.');
end
function test15(cfg)
[a,b]=roundTripSample(cfg); assert(abs(a.Position(2)-b.Position(2))<1e-12,'Y did not round-trip.');
end
function test16(cfg)
[a,b]=roundTripSample(cfg); e=atan2(sin(a.yaw-b.yaw),cos(a.yaw-b.yaw));
assert(abs(e)<1e-12,'Yaw did not round-trip.');
end
function test17(cfg)
[a,b]=roundTripSample(cfg); assert(norm(a.Velocity-b.Velocity)<1e-12, ...
    'Velocity magnitude/direction did not round-trip.');
end
function test18()
a=mapRoadRunnerActorClass('IndianAutoRickshaw'); b=mapRoadRunnerActorClass('IndianAutoRickshaw');
assert(a==b && a=="auto",'Class mapping is not deterministic.');
end
function test19()
[c,d]=mapRoadRunnerActorClass('unlisted hovercraft');
assert(c=="unknown"&&d.usedFallback,'Unknown class lacks controlled fallback.');
threw=false;
try
    mapRoadRunnerActorClass('unlisted hovercraft',true);
catch
    threw=true;
end
assert(threw,'Strict unknown-class mode did not produce an explicit error.');
end
function test20(cfg)
p=getRoadRunnerPaths(cfg); f=fullfile(p.specificationRoot,'VILLAGE_ROAD_SPEC.md');
assert(isfile(f)&&contains(fileread(f),'Expected autonomy behavior'),'Village specification is invalid.');
end
function test21(cfg)
p=getRoadRunnerPaths(cfg); f=fullfile(p.specificationRoot,'URBAN_INTERSECTION_SPEC.md');
assert(isfile(f)&&contains(fileread(f),'Expected autonomy behavior'),'Urban specification is invalid.');
end
function test22(cfg)
cfg.roadrunner.enabled=false; r=runRoadRunnerBridge(cfg,'village');
assert(r.status=="SKIPPED"&&r.runtimeAPICalls==0,'Disabled mode invoked a runtime API.');
end
function test23(cfg)
a=validateRoadRunnerArchitecture(cfg);
assert(a.manifestScenarioCorrespondence.passed,'Phase 8 data is not manifest-compatible.');
end
function test24(cfg)
m=loadRoadRunnerManifest('village',cfg); s=createVillageRoadScenario(cfg); src=s.actors(1);
rr=canonicalPoseToRoadRunner(struct('Position',src.Position,'Velocity',src.Velocity,'yaw',src.Yaw),m);
rr.ID=src.ID; rr.Name=m.actors(1).roadRunnerActorName; rr.Timestamp=0;
a=roadRunnerToCanonicalActors(rr,m);
required={'ID','TrueClass','ClassID','Class','ActorClass','Name','Position', ...
    'Velocity','Yaw','Orientation','Dimensions'};
assert(all(isfield(a,required))&&a.ID==src.ID&&strcmp(a.Class,src.Class), ...
    'Canonical actor schema was not preserved.');
end
function test25(cfg)
r=validateRoadRunnerEnvironment(cfg); assert(r.validConfiguration,'Integration configuration is invalid.');
end
function test26(cfg)
cfg.roadrunner.enabled=true; cfg.roadrunner.projectRoot=''; c=isRoadRunnerAvailable(cfg);
assert(~c.available&&strlength(c.reason)>0,'Missing project path did not return explanatory status.');
end
function test27(cfg)
cfg.roadrunner.enabled=false; output=evalc('r=mainPhase10(cfg);'); %#ok<NASGU>
assert(r.architectureStatus=="COMPLETE"&&r.runtimeValidationStatus=="PENDING", ...
    'mainPhase10 architecture mode failed.');
end
function test28(architecture)
idx=find([architecture.checks.name]=="Core RoadRunner independence",1);
assert(~isempty(idx)&&architecture.checks(idx).passed,'Core autonomy depends on RoadRunner classes.');
end
function test29(v), assert(v.launch.opened,'RoadRunner project did not open.'); end
function test30(v), assert(v.open.sceneOpened&&v.open.scenarioOpened,'Village scene/scenario did not open.'); end
function test31(u), assert(u.open.sceneOpened&&u.open.scenarioOpened,'Urban scene/scenario did not open.'); end
function test32(v), assert(v.metrics.simulationCreated,'Simulation object was not created.'); end
function test33(v), assert(v.metrics.actorCountMismatch==0,'Actor state read/count failed.'); end
function test34(v), assert(v.metrics.framesExchanged>0,'Ego state was not written/synchronized.'); end
function test35(v), assert(v.metrics.statePositionError<0.25&&v.metrics.yawError<deg2rad(2)&& ...
    v.metrics.speedError<0.25,'Canonical/RoadRunner correspondence exceeds tolerance.'); end
function test36(v,cfg), assert(v.metrics.timeSynchronizationError<=cfg.roadrunner.maxTimeDrift, ...
    'Simulation time synchronization exceeds tolerance.'); end
function test37(v), assert(v.status=="PASS"&&v.metrics.framesExchanged>0,'Village integration run failed.'); end
function test38(u), assert(u.status=="PASS"&&u.metrics.framesExchanged>0,'Urban integration run failed.'); end
function test39(v), assert(v.metrics.statePositionError<0.25&&v.metrics.yawError<deg2rad(2), ...
    'Possible coordinate-axis inversion detected.'); end
function test40(v,u), assert(v.metrics.ActorIDMismatchCount==0&&v.metrics.classMismatchCount==0&& ...
    u.metrics.ActorIDMismatchCount==0&&u.metrics.classMismatchCount==0, ...
    'ActorID/class mapping mismatch detected.'); end

function text=portableJSON(m)
if isfield(m,'manifestPath'),m=rmfield(m,'manifestPath');end; text=jsonencode(m);
end
function [a,b]=roundTripSample(~)
t=0.31; transform=struct('positionRotation',[cos(t) -sin(t) 0;sin(t) cos(t) 0;0 0 1], ...
    'translation',[8 -7 1]);
a=struct('Position',[12.25 -3.75 0.2],'Velocity',[2.1 -1.2 0],'yaw',2.4);
b=roadRunnerPoseToCanonical(canonicalPoseToRoadRunner(a,transform),transform);
end
