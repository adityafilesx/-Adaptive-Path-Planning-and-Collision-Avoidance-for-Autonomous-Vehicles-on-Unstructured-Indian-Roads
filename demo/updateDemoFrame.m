function state = updateDemoFrame(ui,data,index,options)
%UPDATEDEMOFRAME Render recorded truth, predictions, envelopes, path and response.
state=formatDemoState(data,index); f=data.result.log(index);
ax=ui.environment;cla(ax);hold(ax,'on');
road=[-10 110 110 -10;-4.5 -4.5 4.5 4.5];
patch(ax,road(1,:),road(2,:),[.94 .95 .94],'EdgeColor','none');
plot(ax,[-10 110],[-4.5 -4.5],':','Color',[.65 .68 .67]);
plot(ax,[-10 110],[4.5 4.5],':','Color',[.65 .68 .67]);
plot(ax,data.scenario.goalPose(1),data.scenario.goalPose(2),'p', ...
    'Color',[.12 .45 .25],'MarkerSize',15,'LineWidth',2);
text(ax,data.scenario.goalPose(1),data.scenario.goalPose(2)-3,'GOAL','FontSize',10);
plot(ax,[data.result.log(1:index).egoX],[data.result.log(1:index).egoY], ...
    '-','Color',[.1 .55 .65],'LineWidth',2,'Tag','egoTrail');
if ~isempty(state.path),plot(ax,state.path(:,1),state.path(:,2), ...
    '-','Color',[.35 .2 .7],'LineWidth',2,'Tag','activePath');end
preds=data.result.presentationFrames(index).predictions;
for j=1:numel(preds)
    pr=preds{j}; p=pr.Prediction;
    if options.showPredictions
        plot(ax,p.Position(:,1),p.Position(:,2),'--o','Color',[.62 .28 .07], ...
            'MarkerSize',3,'Tag','prediction');
    end
    ar=f.actorRiskDetails([f.actorRiskDetails.ActorID]==pr.ActorID);
    if options.showAdaptiveEnvelopes && ~isempty(ar)
        env=computeUncertaintyFootprint([p.Position(1,:) p.Velocity(1,:)].', ...
            p.Covariance(:,:,1),pr.Class,data.scenario.config);
        angle=linspace(0,2*pi,90); rot=[cos(env.Orientation) -sin(env.Orientation);sin(env.Orientation) cos(env.Orientation)];
        xy=rot*(env.SemiAxes(:).*ar.combinedAdaptiveScale.*[cos(angle);sin(angle)])+env.Center(:);
        patch(ax,xy(1,:),xy(2,:),[.95 .65 .23],'FaceAlpha',.14, ...
            'EdgeColor',[.72 .32 .08],'LineWidth',1.5,'Tag','adaptiveEnvelope');
    end
end
for j=1:numel(f.actorTruth)
    a=f.actorTruth(j); strong=a.ID==state.dominantID;
    drawBody(ax,a.Position(1:2),a.Yaw,a.Dimensions(1:2),[.8 .35 .13],1+strong,'actor');
    label=sprintf('%s %d',a.Class,a.ID);if strong,label=[label '  |  HIGHEST RISK'];end
    text(ax,a.Position(1)+1,a.Position(2)+2,label,'FontSize',10,'FontWeight','bold');
end
drawBody(ax,[f.egoX f.egoY],f.egoYaw, ...
    [data.scenario.config.vehicle.length data.scenario.config.vehicle.width],[.05 .4 .65],2,'ego');
quiver(ax,f.egoX,f.egoY,4*cos(f.egoYaw),4*sin(f.egoYaw),0,'Color',[.05 .3 .55],'LineWidth',2);
text(ax,f.egoX,f.egoY+3,'EGO','FontWeight','bold');
axis(ax,'equal');xlim(ax,[-5 105]);ylim(ax,[-22 22]);grid(ax,'on');
xlabel(ax,'World X (m)');ylabel(ax,'World Y (m)');
title(ax,sprintf('%s  |  %.1f s  |  MATLAB diagnostic view',data.scenario.name,f.time),'FontSize',13);
text(ax,.015,.03,'Purple: planned path   Teal: travelled   Dashed dots: prediction   Amber: adaptive extent', ...
    'Units','normalized','FontSize',9,'BackgroundColor','w');
drawPanel(ui.panel,state,data,index,options);
drawTimelines(ui,data,index,options);
setappdata(ui.figure,'displayedState',state);drawnow;
end
function drawBody(ax,position,yaw,dimensions,color,width,tag)
xy=[-1 1 1 -1;-1 -1 1 1].*(dimensions(:)/2);
r=[cos(yaw) -sin(yaw);sin(yaw) cos(yaw)];xy=r*xy+position(:);
patch(ax,xy(1,:),xy(2,:),color,'FaceAlpha',.7,'EdgeColor',color*.6,'LineWidth',width,'Tag',tag);
end
function drawPanel(ax,s,data,index,o)
cla(ax);axis(ax,[0 1 0 1]);axis(ax,'off');hold(ax,'on');
colors=[.1 .4 .25;.65 .38 .06;.7 .15 .13];k=1;
if s.state=="CAUTIOUS",k=2;elseif s.state=="CONSERVATIVE_STOP",k=3;end
text(ax,0,.97,strrep(s.state,'_',' '),'FontSize',18,'FontWeight','bold','Color',colors(k,:));
text(ax,0,.895,sprintf('RISK  %.3f    |    Safety %.2fx    Speed %.2fx',s.risk,s.safetyScale,s.speedScale),'FontSize',11);
rectangle(ax,'Position',[0 .815 1 .035],'FaceColor',[.93 .94 .95],'EdgeColor','none');
if s.risk>0,rectangle(ax,'Position',[0 .815 s.risk .035],'FaceColor',colors(k,:),'EdgeColor','none');end
th=data.scenario.config.governor.thresholds;
for value=[th.cautiousEnter th.conservativeEnter],plot(ax,[value value],[.805 .86],'k-');text(ax,value,.775,sprintf('%.2f',value),'FontSize',9);end
text(ax,0,.71,sprintf('ACTUAL  %.1f m/s    TARGET  %.1f m/s',s.actualSpeed,s.desiredSpeed),'FontSize',13,'FontWeight','bold');
text(ax,0,.655,sprintf('Nominal %.1f m/s   |   Replan urgency %.2f',data.scenario.config.control.baseSpeed,s.urgency),'FontSize',11);
if ~isempty(fieldnames(s.actor))
    a=s.actor;c=a.collisionDiagnostics;
    explanation=sprintf(['DOMINANT: %s %d\nConfidence %.2f    Distance %.1f m\n' ...
        'CPA distance %.1f m    CPA time %s\nActor risk %.3f    Envelope %.2fx'], ...
        a.perceivedClass,a.ActorID,a.confidence,a.distance,c.cpaDistance,finiteTime(c.cpaTime),a.risk,a.combinedAdaptiveScale);
    text(ax,0,.57,explanation,'FontSize',11,'VerticalAlignment','top');
    if o.showAdvancedExplanation
        text(ax,0,.35,sprintf('Distance %.3f | Collision %.3f\nConfidence %.3f | Uncertainty %.3f\nClass weight %.3f | Raw risk %.3f', ...
            a.distanceContribution,a.collisionContribution,a.confidenceContribution,a.uncertaintyContribution,a.classWeight,a.rawRisk), ...
            'FontSize',10,'VerticalAlignment','top');
    end
end
status=sprintf('Path safe: %s   |   Collision observed: %s',yesno(s.pathSafe),yesno(s.collision));
if ~s.pathSafe&&s.desiredSpeed==0,status=[status newline 'Braking response: target speed is zero'];end
text(ax,0,.22,status,'FontSize',10,'VerticalAlignment','top');
if s.goal
    label=sprintf('GOAL REACHED  |  %.1f s\nCollision: %s  |  Replans: %d',s.time,yesno(s.collision),data.result.numberOfReplans);
elseif index==numel(data.result.log) && (~isfield(data,'isLive') || ~data.isLive)
    label=data.result.terminationReason;
else
    label=char(s.replanText);
end
text(ax,0,.11,label,'FontSize',9,'FontWeight','bold','VerticalAlignment','top');
if o.showPerformance
    pe=data.result.planEvents;previous=find([pe.time]<=s.time,1,'last');lastLatency=NaN;
    if ~isempty(previous),lastLatency=1000*pe(previous).latencySeconds;end
    text(ax,0,.01,sprintf('Phase 11 global: planner mean %.2f ms | ACARG %.3f ms\nLast saved planner invocation: %.2f ms (not rendering time)', ...
        data.evidence.statisticalSummary.meanPlannerLatencyMs,data.evidence.acargOverhead.meanACARGComputeTimeMs,lastLatency),'FontSize',8);
end
end
function drawTimelines(ui,data,index,o)
log=data.result.log(1:index);t=[log.time];fullTime=max(1,data.result.log(end).time);
ax=ui.risk;cla(ax);hold(ax,'on');
if o.showRiskPlot
    plot(ax,t,[log.totalRisk],'-','LineWidth',1.8,'Color',[.62 .26 .06]);
    yline(ax,.35,'--','Caution entry','FontSize',8,'Color',[.45 .35 .2]);yline(ax,.70,':','Stop entry','FontSize',8,'Color',[.55 .2 .2]);
    states=string({log.acargState});idx=find(states(2:end)~=states(1:end-1))+1;
    plot(ax,t(idx),[log(idx).totalRisk],'ks','MarkerSize',5);
end
xline(ax,t(end),':');xlim(ax,[0 fullTime]);ylim(ax,[0 1]);title(ax,'Risk and governor transitions');xlabel(ax,'Simulation time (s)');grid(ax,'on');
ax=ui.speed;cla(ax);hold(ax,'on');
if o.showSpeedPlot
    plot(ax,t,[log.egoSpeed],'-','Color',[.05 .4 .65],'LineWidth',1.8);
    plot(ax,t,[log.desiredSpeed],'--','Color',[.5 .25 .55],'LineWidth',1.5);
    legend(ax,{'Actual','Desired'},'Location','southwest','FontSize',8,'Color','w','TextColor','k','AutoUpdate','off');
end
xline(ax,t(end),':');xlim(ax,[0 fullTime]);ylim(ax,[0 data.scenario.config.control.baseSpeed+1]);
title(ax,'Physical speed response');xlabel(ax,'Simulation time (s)');ylabel(ax,'m/s');grid(ax,'on');
ax=ui.events;cla(ax);axis(ax,'off');
events=buildDemoEvents(data.result);events=events(events.Time<=t(end),:);first=max(1,height(events)-3);
lines="RECENT EVENTS";
for i=first:height(events)
    desc=events.Description(i);if strlength(desc)>52,desc=extractBefore(desc,50)+"...";end
    lines(end+1)=sprintf('%.1f s  %s',events.Time(i),desc); %#ok<AGROW>
end
text(ax,0,1,strjoin(lines,newline),'VerticalAlignment','top','FontSize',10,'Interpreter','none');
end
function s=yesno(v)
if v,s='YES';else,s='NO';end
end
function s=finiteTime(t)
if isfinite(t),s=sprintf('%.1f s',t);else,s='not approaching';end
end
