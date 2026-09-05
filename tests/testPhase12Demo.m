% testPhase12Demo: real graphics, full-frame fidelity, exports and live observer.
projectRoot=fileparts(fileparts(mfilename('fullpath')));addpath(genpath(projectRoot));
o=demoConfig();o.visible='off';o.animate=false;
d=loadDemoData(o);sourceBefore=dir(d.sourceFile);original=d.result;
d=captureDemoData(d);ui=createDemoFigure(o);
states=arrayfun(@(k) formatDemoState(d,k),1:numel(d.result.log));
events=buildDemoEvents(d.result);
testOutput=tempname;mkdir(testOutput);
artifacts=exportDemoEvidence(d,testOutput);
exported=mainPhase12(struct('data',d,'mode','EXPORT','visible','off', ...
    'animate',false,'holdFinalFrame',false,'outputRoot',testOutput));
passed=0;failed=0;
for testIndex=1:35
    try
        check(testIndex,d,original,ui,o,states,events,artifacts,exported,sourceBefore);
        passed=passed+1;
    catch info
        failed=failed+1;fprintf('PHASE 12 TEST %d FAILED: %s\n',testIndex,info.message);
    end
end
close(ui.figure);
phase12TestResult=struct('passed',passed,'failed',failed,'exportDirectory',testOutput);
fprintf('testPhase12Demo: %d passed, %d failed.\n',passed,failed);
if failed,error('testPhase12Demo:Failures','One or more Phase 12 tests failed.');end

function check(n,d,original,ui,o,s,events,a,e,before)
l=d.result.log;k=min(35,numel(l));
switch n
    case 1,assert(o.enabled&&strcmp(o.mode,'REPLAY')&&o.frameRate==10);
    case 2,assert(strcmp(d.scenario.name,'Sudden Cattle Crossing'));
    case 3,assert(d.replayVerified&&numel(d.result.presentationFrames)==numel(l));
    case 4,assert(isgraphics(ui.figure)&&numel(findall(ui.figure,'Type','axes'))==5);
    case 5
        updateDemoFrame(ui,d,k,o);h=findobj(ui.environment,'Tag','ego');
        assert(abs(mean(h.XData)-l(k).egoX)<1e-10&&abs(mean(h.YData)-l(k).egoY)<1e-10);
    case 6
        h=findobj(ui.environment,'Tag','actor');assert(numel(h)==numel(l(k).actorTruth));
        assert(abs(mean(h(1).XData)-l(k).actorTruth(1).Position(1))<1e-10);
    case 7,assert(~isempty(findobj(ui.environment,'Tag','prediction')));
    case 8,assert(~isempty(findobj(ui.environment,'Tag','adaptiveEnvelope')));
    case 9,assert(isequal([s.dominantID],arrayfun(@(x) x.acargDiagnostics.dominantActorID,l).'));
    case 10,assert(isequal([s.risk],[l.totalRisk]));
    case 11,assert(isequal([s.state],string({l.acargState})));
    case 12,assert(isequal([s.speedScale],[l.speedScale]));
    case 13,assert(isequal([s.desiredSpeed],[l.desiredSpeed]));
    case 14,assert(isequal([s.actualSpeed],[l.egoSpeed]));
    case 15
        j=find([l.pathReplaced]&[l.time]>0,1);updateDemoFrame(ui,d,j,o);
        h=findobj(ui.environment,'Tag','activePath');assert(isscalar(h));
        assert(isequal(h.XData(:),s(j).path(:,1))&&~isequal(s(j).path,s(1).path));
    case 16,assert(sum(events.Type=="REPLAN")==sum([l.plannerInvoked]));
    case 17,assert(sum(events.Type=="STATE")==sum(string({l(2:end).acargState})~=string({l(1:end-1).acargState})));
    case 18
        updateDemoFrame(ui,d,k,o);h=findobj(ui.risk,'Type','line');
        assert(any(arrayfun(@(x) isequal(x.XData,[l(1:k).time])&&isequal(x.YData,[l(1:k).totalRisk]),h)));
    case 19
        h=findobj(ui.speed,'Type','line');assert(any(arrayfun(@(x) isequal(x.XData,[l(1:k).time])&&isequal(x.YData,[l(1:k).egoSpeed]),h)));
    case 20,assert(s(end).goal&&~any([s(1:end-1).goal]));
    case 21,assert(~any([s.collision])&&~d.result.collisionOccurred);
    case 22,assert(isfile(a.beforeAfter.png)&&isfile(a.beforeAfter.pdf));
    case 23,assert(isfile(a.confidence.png)&&isfile(a.confidence.pdf));
    case 24,assert(isfile(a.cpa.png)&&isfile(a.cpa.pdf));
    case 25,assert(isfile(a.baseline.png)&&isfile(a.baseline.pdf));
    case 26,assert(height(e.screenshots)==7&&all(isfile(e.screenshots.File)));
    case 27
        assert(strcmp(e.videoStatus,'GENERATED')||startsWith(e.videoStatus,'UNSUPPORTED'));
        if strcmp(e.videoStatus,'GENERATED')
            v=VideoReader(e.videoFile);assert(v.FrameRate==o.frameRate&&v.Duration>=l(end).time/o.playbackSpeed);
            assert(hasFrame(v));readFrame(v);
        end
    case 28,assert(isequaln(original,rmfield(d.result,'presentationFrames'))&&isequaln(e.metrics,original.metrics));
    case 29
        after=dir(d.sourceFile);assert(before.bytes==after.bytes&&before.datenum==after.datenum);
        saved=load(d.sourceFile,'evaluation');
        idx=find(arrayfun(@(x) strcmp(x.scenario.name,d.scenario.name),saved.evaluation.dataset.scenarioRuns),1);
        assert(isequaln(saved.evaluation.dataset.scenarioRuns(idx).result,original));
    case 30,assert(e.goalReached&&~e.collisionOccurred&&isfile(e.summaryFile)&&isfile(e.eventFile));
    case 31
        for j=1:numel(l)
            recent=any([l(1:j).plannerInvoked]&l(j).time-[l(1:j).time]<=.8+eps);
            assert(s(j).replan==recent);
        end
    case 32
        q=o;q.scenario='Confidence Drop';secondary=captureDemoData(loadDemoData(q));
        assert(secondary.replayVerified&&~isempty(secondary.result.log));
        updateDemoFrame(ui,secondary,20,q);
    case 33
        live=mainPhase12(struct('data',d,'mode','LIVE','visible','off','animate',false,'holdFinalFrame',false,'outputRoot',fileparts(e.summaryFile)));
        assert(live.replayVerified&&isequaln(live.metrics,original.metrics));
    case 34
        q=o;q.showAdvancedExplanation=true;q.showPerformance=true;
        updateDemoFrame(ui,d,k,q);handles=findobj(ui.panel,'Type','text');
        texts=arrayfun(@(h) strjoin(string(h.String),newline),handles);
        assert(any(contains(texts,'Class weight'))&&any(contains(texts,'Phase 11 global')));
    case 35
        for j=1:numel(l)
            assert(isequal(s(j).path,d.result.presentationFrames(j).pathStates));
            assert(s(j).pathSafe==l(j).pathSafe&&s(j).safetyScale==l(j).safetyScale);
        end
end
end
