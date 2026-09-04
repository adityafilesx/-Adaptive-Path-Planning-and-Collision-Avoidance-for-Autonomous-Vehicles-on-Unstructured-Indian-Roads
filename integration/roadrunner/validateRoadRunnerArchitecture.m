function report = validateRoadRunnerArchitecture(cfg)
%VALIDATEROADRUNNERARCHITECTURE Audit static integration on every platform.

    if nargin<1 || isempty(cfg), cfg=config(); end
    paths=getRoadRunnerPaths(cfg); checks=repmat(struct('name',"", ...
        'passed',false,'detail',""),0,1);
    requiredDirs={'manifests','specs','project','assets','exports','validation'};
    for i=1:numel(requiredDirs)
        p=fullfile(paths.roadRunnerRoot,requiredDirs{i});
        checks(end+1)=makeCheck("Directory "+requiredDirs{i},isfolder(p),string(p)); %#ok<AGROW>
    end
    keys=["village","urban","highway","denseMarket","cattle"];
    manifests=cell(size(keys));
    for i=1:numel(keys)
        try
            manifests{i}=loadRoadRunnerManifest(keys(i),cfg);
            validation=validateRoadRunnerManifest(manifests{i});
            checks(end+1)=makeCheck("Manifest "+keys(i),validation.valid, ...
                "actors="+validation.actorCount); %#ok<AGROW>
        catch info
            checks(end+1)=makeCheck("Manifest "+keys(i),false,string(info.message)); %#ok<AGROW>
        end
    end
    primarySpecs=["VILLAGE_ROAD_SPEC.md","URBAN_INTERSECTION_SPEC.md"];
    requiredTerms={{'Purpose','Geometry','Ego','Logical actors','Expected autonomy behavior','Validation'}, ...
        {'Purpose','Geometry','Ego','Logical actors','Expected autonomy behavior','Validation'}};
    for i=1:numel(primarySpecs)
        p=fullfile(paths.specificationRoot,primarySpecs(i)); valid=isfile(p);
        if valid
            text=fileread(p);
            valid=all(cellfun(@(term) contains(text,term),requiredTerms{i}));
        end
        checks(end+1)=makeCheck("Specification "+primarySpecs(i),valid,string(p)); %#ok<AGROW>
    end
    [positionError,yawError,velocityError]=roundTripAudit();
    checks(end+1)=makeCheck("Coordinate round trip", ...
        max([positionError yawError velocityError])<1e-10, ...
        sprintf('position %.3g m, yaw %.3g rad, velocity %.3g m/s', ...
            positionError,yawError,velocityError));
    samples=["Sedan","IndianAutoRickshaw","Citizen_Male","Bicycle", ...
        "PushCart","Cattle","SemiTruck"];
    mapped=arrayfun(@(v) mapRoadRunnerActorClass(v),samples);
    checks(end+1)=makeCheck("Actor class mappings", ...
        isequal(mapped,["car","auto","pedestrian","bicycle","pushcart","cattle","truck"]), ...
        strjoin(mapped,','));
    correspondence=manifestScenarioAudit(manifests,cfg);
    checks(end+1)=makeCheck("Phase 8 manifest correspondence", ...
        correspondence.passed,correspondence.detail);
    [independent,detail]=coreIndependenceAudit(paths.repositoryRoot);
    checks(end+1)=makeCheck("Core RoadRunner independence",independent,detail);
    entryFiles=["mainPhase6.m","mainPhase7.m","mainPhase8.m","mainPhase9.m", ...
        "tests/testPerception.m","tests/testTracking.m","tests/testOccupancy.m", ...
        "tests/testPlanning.m","tests/testACARG.m","tests/testClosedLoop.m", ...
        "tests/testPhase8Scenarios.m","tests/testPhase9Robustness.m"];
    available=arrayfun(@(f) isfile(fullfile(paths.repositoryRoot,f)),entryFiles);
    checks(end+1)=makeCheck("Core regression entry points",all(available), ...
        sum(available)+"/"+numel(available)+" available");
    environment=validateRoadRunnerEnvironment(cfg);
    checks(end+1)=makeCheck("Integration configuration", ...
        environment.validConfiguration,strjoin(environment.errors,' | '));
    report=struct('passed',all([checks.passed]),'checks',checks, ...
        'passedCount',sum([checks.passed]),'failedCount',sum(~[checks.passed]), ...
        'positionRoundTripError',positionError,'yawRoundTripError',yawError, ...
        'velocityRoundTripError',velocityError,'environment',environment, ...
        'manifestScenarioCorrespondence',correspondence);
end

function c=makeCheck(name,passed,detail)
c=struct('name',string(name),'passed',logical(passed),'detail',string(detail));
end
function [pe,ye,ve]=roundTripAudit()
a=0.37; transform=struct('positionRotation',[cos(a) -sin(a) 0;sin(a) cos(a) 0;0 0 1], ...
    'translation',[11 -4 2]);
samples=[0 0 0 0 0 0 0;12.3 -4.5 0.2 2.7 3.1 -1.4 0; -7 8 0 -2.9 -2 4 0];
pe=0;ye=0;ve=0;
for i=1:size(samples,1)
    s=struct('Position',samples(i,1:3),'yaw',samples(i,4), ...
        'Velocity',samples(i,5:7));
    b=roadRunnerPoseToCanonical(canonicalPoseToRoadRunner(s,transform),transform);
    pe=max(pe,norm(b.Position-s.Position)); ve=max(ve,norm(b.Velocity-s.Velocity));
    ye=max(ye,abs(atan2(sin(b.yaw-s.yaw),cos(b.yaw-s.yaw))));
end
end
function result=manifestScenarioAudit(manifests,cfg)
result=struct('passed',false,'detail',"");
if any(cellfun(@isempty,manifests)), result.detail="Manifest load failure."; return; end
scenarios=getPhase8Scenarios(cfg); issues=strings(0,1);
for i=1:numel(manifests)
    m=manifests{i}; idx=find(cellfun(@(s) strcmp(s.name,m.scenarioName),scenarios),1);
    if isempty(idx), issues(end+1)="No Phase 8 scenario for "+string(m.scenarioName); continue; end %#ok<AGROW>
    s=scenarios{idx}; ma=m.actors; sa=s.actors;
    if numel(ma)~=numel(sa) || any([ma.logicalActorID]~=[sa.ID]) || ...
            ~isequal(string({ma.canonicalClass}),string({sa.Class}))
        issues(end+1)="Actor identity mismatch: "+string(m.scenarioKey); continue; %#ok<AGROW>
    end
    for j=1:numel(ma)
        mp=[ma(j).initialPose.x ma(j).initialPose.y ma(j).initialPose.z];
        mv=[ma(j).velocity.x ma(j).velocity.y ma(j).velocity.z];
        md=[ma(j).dimensions.length ma(j).dimensions.width ma(j).dimensions.height];
        if norm(mp-sa(j).Position)>1e-12 || norm(mv-sa(j).Velocity)>1e-12 || ...
                norm(md-sa(j).Dimensions)>1e-12
            issues(end+1)="Actor state mismatch: "+ma(j).logicalActorID; %#ok<AGROW>
        end
    end
    if norm([m.goalPose.x m.goalPose.y m.goalPose.yaw]-s.goalPose)>1e-12
        issues(end+1)="Goal mismatch: "+string(m.scenarioKey); %#ok<AGROW>
    end
end
result.passed=isempty(issues);
if result.passed, result.detail="All five manifests exactly match Phase 8 logical states.";
else, result.detail=strjoin(issues,' | '); end
end
function [passed,detail]=coreIndependenceAudit(root)
folders=["perception","tracking","occupancy","governor","planning","control","robustness"];
hits=strings(0,1);
for i=1:numel(folders)
    files=dir(fullfile(root,folders(i),'**','*.m'));
    for j=1:numel(files)
        p=fullfile(files(j).folder,files(j).name);
        if contains(lower(fileread(p)),'roadrunner'), hits(end+1)=string(p); end %#ok<AGROW>
    end
end
passed=isempty(hits);
if passed, detail="No core module references RoadRunner."; else, detail=strjoin(hits,' | '); end
end
