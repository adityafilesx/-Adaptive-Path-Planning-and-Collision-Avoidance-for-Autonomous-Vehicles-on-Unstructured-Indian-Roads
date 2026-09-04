function result = runRoadRunnerBridge(cfg, scenarioKey, options)
%RUNROADRUNNERBRIDGE Gated short state-exchange validation for genuine runtime.

    if nargin<1 || isempty(cfg), cfg=config(); end
    if nargin<2 || isempty(scenarioKey), scenarioKey='village'; end
    if nargin<3, options=struct(); end
    if ~isfield(options,'maxFrames'), options.maxFrames=5; end
    timer=tic; capability=isRoadRunnerAvailable(cfg);
    result=struct('status',"SKIPPED",'message',capability.reason, ...
        'scenarioKey',string(scenarioKey),'manifest',struct(), ...
        'metrics',emptyRoadRunnerMetrics(),'runtimeAPICalls',0, ...
        'launch',struct(),'open',struct(),'simulation',[],'coreResult',struct());
    if ~capability.runtimeReady
        if capability.available && ~cfg.roadrunner.enabled
            result.message="RoadRunner available but cfg.roadrunner.enabled is false.";
        end
        result.metrics.integrationRuntime=toc(timer); return;
    end
    manifest=loadRoadRunnerManifest(scenarioKey,cfg); result.manifest=manifest;
    launch=launchRoadRunnerProject(cfg); result.launch=launch;
    result.runtimeAPICalls=result.runtimeAPICalls+launch.runtimeAPICalls;
    if launch.status~="PASS", result.status="FAIL"; result.message=launch.message; return; end
    result.metrics.roadRunnerConnected=true;
    opened=openRoadRunnerScenario(launch.app,manifest,cfg); result.open=opened;
    result.runtimeAPICalls=result.runtimeAPICalls+opened.runtimeAPICalls;
    if opened.status~="PASS", result.status="FAIL"; result.message=opened.message; return; end
    result.metrics.scenarioOpened=true;
    try
        result.runtimeAPICalls=result.runtimeAPICalls+1;
        rrSimulation=createSimulation(launch.app);
        result.simulation=rrSimulation; result.metrics.simulationCreated=true;
        set(rrSimulation,StepSize=cfg.roadrunner.controlStep);
        result.runtimeAPICalls=result.runtimeAPICalls+1;
        demo=phase8Scenario(manifest,cfg);
        result.coreResult=runClosedLoopSimulation(demo);
        frameLimit=min(options.maxFrames,size(result.coreResult.egoHistory,1)-1);
        ego=historyEgo(result.coreResult.egoHistory(1,:));
        write=writeCanonicalEgoState(rrSimulation,ego,manifest);
        result.runtimeAPICalls=result.runtimeAPICalls+write.runtimeAPICalls;
        if ~write.written, error('RoadRunner:EgoWrite', '%s', write.message); end
        [actors,diagnostics]=extractRoadRunnerActors(rrSimulation,manifest,0);
        correspondence=compareRoadRunnerSceneCorrespondence(actors,manifest);
        maxPositionError=correspondence.statePositionError;
        maxYawError=correspondence.yawError;
        maxSpeedError=correspondence.speedError;
        maxTimeError=0;
        for frame=1:frameLimit
            set(rrSimulation,SimulationCommand="Step");
            result.runtimeAPICalls=result.runtimeAPICalls+1;
            ego=historyEgo(result.coreResult.egoHistory(frame+1,:));
            write=writeCanonicalEgoState(rrSimulation,ego,manifest);
            result.runtimeAPICalls=result.runtimeAPICalls+write.runtimeAPICalls;
            if ~write.written, error('RoadRunner:EgoWrite','%s',write.message); end
            [readback,readStatus]=readRoadRunnerEgoState(rrSimulation,manifest);
            result.runtimeAPICalls=result.runtimeAPICalls+readStatus.runtimeAPICalls;
            if ~readStatus.read, error('RoadRunner:EgoRead','%s',readStatus.message); end
            rrTime=double(get(rrSimulation,"SimulationTime"));
            result.runtimeAPICalls=result.runtimeAPICalls+1;
            sync=validateTimeSynchronization(frame*cfg.roadrunner.controlStep, ...
                rrTime,frame,cfg);
            maxTimeError=max(maxTimeError,sync.timeSynchronizationError);
            maxPositionError=max(maxPositionError,norm(readback.Position-ego.Position));
            maxYawError=max(maxYawError,abs(atan2(sin(readback.yaw-ego.yaw), ...
                cos(readback.yaw-ego.yaw))));
            maxSpeedError=max(maxSpeedError,norm(readback.Velocity-ego.Velocity));
            result.metrics.framesExchanged=result.metrics.framesExchanged+1;
        end
        result.metrics.statePositionError=maxPositionError;
        result.metrics.yawError=maxYawError;
        result.metrics.speedError=maxSpeedError;
        result.metrics.actorCountMismatch=diagnostics.actorCountMismatch;
        result.metrics.ActorIDMismatchCount=correspondence.ActorIDMismatchCount;
        result.metrics.classMismatchCount=correspondence.classMismatchCount;
        result.metrics.timeSynchronizationError=maxTimeError;
        synchronized=maxTimeError<=cfg.roadrunner.maxTimeDrift;
        if correspondence.corresponds && synchronized && ...
                result.metrics.framesExchanged==frameLimit
            result.status="PASS";
            result.message="RoadRunner project, scenario, and short synchronized state exchange validated.";
        else
            result.status="FAIL";
            result.message="Runtime connected, but manifest/state correspondence failed.";
        end
    catch info
        result.status="FAIL";
        result.message="RoadRunner bridge validation failed: "+string(info.message);
    end
    result.metrics.integrationRuntime=toc(timer);
end

function demo=phase8Scenario(manifest,cfg)
scenarios=getPhase8Scenarios(cfg);
idx=find(cellfun(@(s) strcmp(s.name,manifest.scenarioName),scenarios),1);
if isempty(idx), error('RoadRunner:ScenarioMapping','No Phase 8 scenario matches manifest.'); end
demo=scenarios{idx};
end
function ego=historyEgo(row)
ego=struct('x',row(1),'y',row(2),'yaw',row(3),'speed',row(4), ...
    'Position',[row(1) row(2) 0], ...
    'Velocity',[row(4)*cos(row(3)) row(4)*sin(row(3)) 0]);
end
