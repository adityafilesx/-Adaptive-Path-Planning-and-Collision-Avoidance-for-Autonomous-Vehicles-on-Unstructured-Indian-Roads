function result=testScenarioVideoExport(folder)
%TESTSCENARIOVIDEOEXPORT Actual videos/replays, no synthetic media fixtures.
addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));
o=scenarioVideoConfig();
if nargin<1
    files=dir(fullfile(o.outputRoot,'videos','all_scenarios','run_*','video_manifest.csv'));
    assert(~isempty(files),'VideoTest:Missing','Required video evidence has not been exported.');
    [~,idx]=max([files.datenum]);folder=string(files(idx).folder);
end
m=readtable(fullfile(folder,'video_manifest.csv'),'TextType','string','Delimiter',',','VariableNamingRule','preserve');catalog=scenarioVideoCatalog();
assert(height(m)==13,'VideoTest:Incomplete','All 13 videos must exist; video tests do not silently skip.');
data=cell(13,1);proofs=cell(13,1);
for k=1:13
    loaded=load(m.SourceLog(k),'data');data{k}=loaded.data;proofs{k}=validateScenarioVideo(m(k,:));
end
loaded=load(m.SourceEvaluation(1),'evaluation');e=loaded.evaluation;
rows=struct('Test',{},'Status',{},'Detail',{});
for n=1:40
    try,check(n);status="PASS";detail="";
    catch info,status="FAIL";detail=string(info.message);end
    rows(end+1)=struct('Test',n,'Status',status,'Detail',detail); %#ok<AGROW>
    fprintf('SCENARIO VIDEO TEST %02d: %s %s\n',n,status,detail);
end
result=struct('passed',sum([rows.Status]=="PASS"),'failed',sum([rows.Status]=="FAIL"), ...
    'tests',struct2table(rows),'manifest',string(fullfile(folder,'video_manifest.csv')));
writetable(result.tests,fullfile(folder,'scenario_video_test_results.csv'));
fprintf('testScenarioVideoExport: %d passed, %d failed.\n',result.passed,result.failed);
assert(result.failed==0,'VideoTest:Failures','Video evidence checks failed.');
    function check(n)
        switch n
            case 1,assert(height(catalog)==13&&numel(unique(catalog.Scenario))==13);
            case 2,assert(sum(m.Phase==8)==5);
            case 3,assert(sum(m.Phase==9)==8);
            case 4,assert(isequal(m.Scenario,catalog.Scenario)&&isequal(m.VideoID,catalog.VideoID));
            case 5,assert(all(isfile(m.File))&&all(arrayfun(@positiveFile,m.File)));
            case 6,assert(all(cellfun(@(p) p.FramesDecoded>0&&p.Status=="PASS",proofs)));
            case 7,assert(all(m.Duration>0)&&all(m.ExpectedFrames>0));
            case 8,assert(all(m.Width==1440&m.Height==900&m.FrameRate==10));
            case 9,assert(all(m.ExportStatus=="VALIDATED")&&all(m.RendererVersion==2));
            case 10,assert(all(isfile(m.SourceLog))&&all(isfile(m.SourceEvaluation)));
            case 11
                for j=1:5,r=e.dataset.scenarioRuns(j);assert(isequaln(data{j}.result.log,r.result.log)&&isequaln(data{j}.result.metrics,r.result.metrics));end
            case 12
                for j=6:13,idx=find(string({e.robustness.scenarioRuns.scenarioName})==m.Scenario(j),1);r=e.robustness.scenarioRuns(idx).detail.result;assert(isequaln(data{j}.result.log,r.log)&&isequaln(data{j}.result.metrics,r.metrics));end
            case 13,assert(all(cellfun(@(d) d.replayVerified&&d.benchmarkVersion=="POST_PHASE9_FIX",data)));
            case 14,assert(m.Outcome(2)=="SAFE_TERMINATION"&&m.SafeTermination(2)&&~m.GoalReached(2)&&~m.Collision(2));
            case 15,assert(contains(m.TerminationReason(2),'repeated planning failures'));
            case 16,assert(all(m.GoalReached([1 3 4 5]))&&~any(m.Collision));
            case 17,assert(sum(m.ScreenshotCount)==39&&all(isfile([m.InitialScreenshot;m.KeyScreenshot;m.FinalScreenshot])));
            case 18
                paths=[m.InitialScreenshot;m.KeyScreenshot;m.FinalScreenshot];
                for j=1:numel(paths),p=imfinfo(paths(j));assert(p.Width==1440&&p.Height==900);end
            case 19,assert(isfile(fullfile(folder,'VIDEO_INDEX.md')));indexText=fileread(fullfile(folder,'VIDEO_INDEX.md'));assert(all(arrayfun(@(name) contains(indexText,name),m.Scenario)));
            case 20
                l=data{6}.result.log;confidence=arrayfun(@(f) f.detections(1).Confidence,l);
                assert(min(confidence)<max(confidence)&&any(diff(confidence)<0)&&any(diff(confidence)>0));
            case 21,l=data{7}.result.log;assert(any(arrayfun(@(f) ~f.detections(1).IsDetected,l)));
            case 22,l=data{8}.result.log;vy=arrayfun(@(f) f.actorTruth(1).Velocity(2),l);assert(any(vy>0)&&any(vy<0));
            case 23,l=data{9}.result.log;ids=arrayfun(@(f) f.acargDiagnostics.dominantActorID,l);assert(numel(unique(ids(isfinite(ids))))>1);
            case 24,l=data{11}.result.log;failed=find([l.plannerInvoked]&~[l.planningSucceeded],1);assert(~isempty(failed)&&any([l(failed+1:end).planningSucceeded]));
            case 25
                for j=1:13,l=data{j}.result.log;assert(all([l(~[l.pathSafe]).desiredSpeed]==0));end
            case 26,l=data{12}.result.log;stop=string({l.acargState})=="CONSERVATIVE_STOP";assert(any(stop)&&all([l(stop).desiredSpeed]==0)&&any([l(stop).egoSpeed]>0));
            case 27,l=data{12}.result.log;stop=string({l.acargState})=="CONSERVATIVE_STOP";assert(any(stop(1:end-1)&~stop(2:end))&&isfinite(m.RecoveryTime(12)));
            case 28,assert(m.SafeTermination(8)&&m.SafeTermination(12)&&~m.GoalReached(8)&&~m.GoalReached(12));
            case 29
                for j=1:13,l=data{j}.result.log;[risk,k]=max([l.totalRisk]);assert(abs(m.PeakRisk(j)-risk)<1e-12&&abs(m.KeySimulationTime(j)-l(k).time)<1e-9);end
            case 30,assert(max(abs(m.KeyVideoTime-m.KeySimulationTime-m.TitleSeconds))<1e-9);
            case 31,assert(all(isfile(m.File+".timeline.csv"))&&all(isfile(m.File+".events.csv")));
            case 32
                caption=scenarioReplanCaption(data{1},1);assert(contains(caption,'INITIAL PLAN READY')&&~contains(caption,'FAILED'));
                q=demoConfig();q.visible='off';ui=createDemoFigure(q);guard=onCleanup(@() close(ui.figure));
                [~,s]=renderScenarioVideoFrame(ui,data{1},1,o);assert(s.replanText==caption);
                labels=findobj(ui.panel,'Type','text');labelText=arrayfun(@(h) strjoin(string(h.String),newline),labels);
                assert(any(contains(labelText,'INITIAL PLAN READY'))&&~any(contains(labelText,'PLAN FAILED / BRAKING')));
            case 33,q=m(1,:);q.Outcome="MADE_UP";mustFail(@() validateScenarioVideo(q),'Video:Outcome');
            case 34,q=m(1,:);q.ExpectedFrames=q.ExpectedFrames+1;mustFail(@() validateScenarioVideo(q),'Video:Timeline');
            case 35,q=m(1,:);q.RendererVersion=1;mustFail(@() validateScenarioVideo(q),'Video:RendererVersion');
            case 36,c=getIDDExecutionConfig();assert(~c.enabled&&~c.runTraining&&c.pretrainedName=="tiny-coco");
            case 37,c=getIDDExecutionConfig(struct('profile',"FULL"));assert(c.pretrainedName=="small-coco"&&isinf(c.trainLimit)&&~c.runTraining);
            case 38,c=validateIDDExecutionEnvironment();assert(isfield(c,'ParallelComputingAvailable')&&c.YOLOXAvailable==~isempty(which('yoloxObjectDetector')));
            case 39,s=getPerceptionSchemas();assert(~any(ismember({'Position','Velocity'},s.ImageDetection.fields))&&~s.ImageDetection.metricReady);
            case 40
                source=dir(m.SourceEvaluation(1));assert(source.bytes==data{1}.sourceIdentity.bytes&&source.datenum==data{1}.sourceIdentity.datenum);
        end
    end
end
function mustFail(callback,id)
try,callback();catch info,assert(strcmp(info.identifier,id),'Unexpected failure: %s',info.message);return;end
error('VideoTest:ExpectedFailure','Invalid metadata was accepted.');
end
function valid=positiveFile(path)
file=dir(path);valid=~isempty(file)&&file.bytes>0;
end
