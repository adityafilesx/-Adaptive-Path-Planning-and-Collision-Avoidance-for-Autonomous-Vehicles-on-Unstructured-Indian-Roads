function files = exportDemoEvidence(data,outputDirectory)
%EXPORTDEMOEVIDENCE Native MATLAB figures grounded in saved Phase 11 evidence.
if ~isfolder(outputDirectory),mkdir(outputDirectory);end
files=struct();
f=newFigure();ax=axes(f);hold(ax,'on');
shots=selectDemoScreenshots(data);k=shots.Frame(5);
p=data.result.presentationFrames;
plot(ax,p(1).pathStates(:,1),p(1).pathStates(:,2),'--','LineWidth',2);
plot(ax,p(k).pathStates(:,1),p(k).pathStates(:,2),'-','LineWidth',2);
plot(ax,[data.result.log(1:k).egoX],[data.result.log(1:k).egoY],'-','LineWidth',2);
legend(ax,{'Initial planned path',sprintf('Updated plan at %.1f s',data.result.log(k).time),'Travelled to event'},'Location','best');
legend(ax,'AutoUpdate','off');
frame=data.result.log(k);dominant=frame.acargDiagnostics.dominantActorID;
actor=frame.actorTruth([frame.actorTruth.ID]==dominant);
if ~isempty(actor)
    plot(ax,actor.Position(1),actor.Position(2),'s','MarkerSize',10,'LineWidth',2,'Color',[.7 .25 .05]);
    text(ax,actor.Position(1)+1,actor.Position(2)+1,sprintf('Dominant %s %d',actor.Class,actor.ID));
    details=frame.actorRiskDetails([frame.actorRiskDetails.ActorID]==dominant);
    predictions=p(k).predictions;
    pr=predictions{find(cellfun(@(x) x.ActorID==dominant,predictions),1)};
    env=computeUncertaintyFootprint(pr.Prediction.Position(1,:).', ...
        pr.Prediction.Covariance(:,:,1),pr.Class,data.scenario.config);
    theta=linspace(0,2*pi,100);rotation=[cos(env.Orientation) -sin(env.Orientation);sin(env.Orientation) cos(env.Orientation)];
    xy=rotation*(env.SemiAxes(:).*details.combinedAdaptiveScale.*[cos(theta);sin(theta)])+env.Center(:);
    patch(ax,xy(1,:),xy(2,:),[.95 .65 .23],'FaceAlpha',.15,'EdgeColor',[.7 .25 .05]);
end
title(ax,'Online replanning | actual stored path vertices');xlabel(ax,'World X (m)');ylabel(ax,'World Y (m)');grid(ax,'on');
files.beforeAfter=saveFigure(f,'before_after_path');

f=newFigure();tiledlayout(f,2,2,'TileSpacing','compact');
pairs=data.evidence.baseline.pairs;
pair=pairs{find(cellfun(@(x) strcmp(x.scenarioName,'Sudden Cattle Crossing'),pairs),1)};
a=pair.fullRun.result;b=pair.baselineResult;
ax=nexttile;hold(ax,'on');plot(ax,a.egoHistory(:,1),a.egoHistory(:,2),'LineWidth',2);
plot(ax,b.egoHistory(:,1),b.egoHistory(:,2),'--','LineWidth',2);
title(ax,'Cattle crossing | travelled trajectories');xlabel(ax,'X (m)');ylabel(ax,'Y (m)');grid(ax,'on');legend(ax,{'ACARG','Fixed margin'},'Location','best');
ax=nexttile;hold(ax,'on');plot(ax,[a.log.time],[a.log.egoSpeed],'LineWidth',2);
plot(ax,[b.log.time],[b.log.egoSpeed],'--','LineWidth',2);title(ax,'Physical speed');xlabel(ax,'Time (s)');ylabel(ax,'m/s');grid(ax,'on');
ax=nexttile;hold(ax,'on');plot(ax,[a.log.time],[a.log.minimumActorDistance],'LineWidth',2);
plot(ax,[b.log.time],[b.log.minimumActorDistance],'--','LineWidth',2);title(ax,'Actor center distance (not body clearance)');xlabel(ax,'Time (s)');ylabel(ax,'m');grid(ax,'on');
ax=nexttile;axis(ax,'off');tab=data.evidence.baseline.table;
tab=tab(tab.Scenario=="Sudden Cattle Crossing",:);lines="RECORDED OUTCOMES";
for i=1:height(tab)
    lines(end+1)=sprintf('%s\n%s | collision %d\nReplans %d | min center distance %.2f m\nSimulation %.1f s | mean speed %.2f m/s\n', ...
        tab.Mode(i),tab.OutcomeClass(i),tab.Collision(i),tab.Replans(i), ...
        tab.MinimumActorDistance(i),tab.SimulationTime(i),tab.MeanSpeed(i)); %#ok<AGROW>
end
text(ax,0,1,strjoin(lines,newline),'VerticalAlignment','top','FontSize',11);
files.baseline=saveFigure(f,'baseline_vs_acarg');

f=newFigure();tiledlayout(f,1,2,'TileSpacing','compact');
c=data.evidence.ablation.confidence;c=c(c.Mode=="FULL_ACARG",:);
ax=nexttile;yyaxis(ax,'left');plot(ax,c.DetectionConfidence,c.ActorRisk,'-o','LineWidth',2);ylabel(ax,'Actor risk');
yyaxis(ax,'right');plot(ax,c.DetectionConfidence,c.AdaptiveScale,'-s','LineWidth',2);ylabel(ax,'Adaptive scale');
ax.XDir='reverse';xlabel(ax,'Detection confidence (decreasing)');title(ax,'Lower confidence + greater uncertainty');grid(ax,'on');
ax=nexttile;axis(ax,'off');lines=["PHASE 11 CONTROLLED EXPERIMENT";"Conf.    Risk     Envelope    State / speed"];
for i=1:height(c),lines(end+1)=sprintf('%.2f     %.3f      %.2fx       %s / %.2f', ...
        c.DetectionConfidence(i),c.ActorRisk(i),c.AdaptiveScale(i),c.GovernorState(i),c.SpeedScale(i));end %#ok<AGROW>
lines=[lines;"";sprintf('Logged uncertainty: %.3f to %.3f',c.Uncertainty(1),c.Uncertainty(end)); ...
    "Same pedestrian geometry; confidence and";"measurement uncertainty vary together."; ...
    "Risk and envelope grow; the state remains";"CAUTIOUS and speed scale remains 0.65.";"No artificial STOP transition is added."];
text(ax,0,.9,strjoin(lines,newline),'VerticalAlignment','top','FontSize',11);
files.confidence=saveFigure(f,'confidence_evidence');

f=newFigure();tiledlayout(f,1,2,'TileSpacing','compact');
c=data.evidence.ablation.cpa;noCPA=c(c.Mode=="NO_CPA_EFFECT",:);c=c(c.Mode=="FULL_ACARG",:);
% Geometry is the exact controlled definition in runACARGAblation/cpaExperiment.
positions={[10 0],[18 6]};velocities={[7 0],[0 -4/3]};times=0:.5:5;
for i=1:2
    ax=nexttile;hold(ax,'on');xy=positions{i}+times.'*velocities{i};
    plot(ax,4*times,zeros(size(times)),'-o','LineWidth',1.5);
    plot(ax,xy(:,1),xy(:,2),'--s','LineWidth',1.5);
    title(ax,sprintf('%s\nDistance %.3f m | CPA %.2f m at %.1f s\nACARG risk %.3f | Without CPA %.3f', ...
        c.Geometry(i),c.PhysicalDistance(i),c.CPADistance(i),c.CPATime(i),c.ActorRisk(i),noCPA.ActorRisk(i)));
    xlabel(ax,'World X (m)');ylabel(ax,'World Y (m)');grid(ax,'on');ylim(ax,[-3 9]);
    legend(ax,{'Ego: 4 m/s','Actor: controlled trajectory'},'Location','best');
end
files.cpa=saveFigure(f,'cpa_evidence');
    function paths=saveFigure(fig,name)
        paths=struct('png',fullfile(outputDirectory,[name '.png']),'pdf',fullfile(outputDirectory,[name '.pdf']));
        exportgraphics(fig,paths.png,'Resolution',150,'BackgroundColor','white');
        exportgraphics(fig,paths.pdf,'ContentType','vector','BackgroundColor','white');close(fig);
    end
end
function f=newFigure()
f=figure('Visible','off','Position',[40 40 1200 620],'Color','white');
set(f,'DefaultAxesColor','white','DefaultAxesXColor',[.12 .15 .2], ...
    'DefaultAxesYColor',[.12 .15 .2],'DefaultTextColor',[.08 .12 .17], ...
    'DefaultTextInterpreter','none','DefaultLegendInterpreter','none', ...
    'DefaultLegendColor','white','DefaultLegendTextColor','black','DefaultAxesFontSize',11);
end
