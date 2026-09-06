function pixels=renderScenarioVideoCard(data,phase,kind,o)
%RENDERSCENARIOVIDEOCARD Actual challenge/outcome; no idealized scenario claims.
f=figure('Visible','off','Color','white','Position',[40 40 o.resolution],'MenuBar','none','ToolBar','none');
guard=onCleanup(@() close(f));
ax=axes(f,'Position',[.06 .08 .88 .84]);axis(ax,[0 1 0 1]);axis(ax,'off');
text(ax,0,.96,sprintf('ACARG  |  PHASE %d  |  MATLAB CLOSED-LOOP EVIDENCE',phase), ...
    'Color',[.1 .4 .5],'FontSize',15,'FontWeight','bold','Interpreter','none');
text(ax,0,.84,data.scenario.name,'FontSize',27,'FontWeight','bold','Color',[.08 .16 .23],'Interpreter','none');
if string(kind)=="TITLE"
    lines=["Primary challenge:";string(data.scenario.description);"";"Watch: "+data.concept;""; ...
        "Authoritative POST_PHASE9_FIX replay | 1x time | 10 fps"; ...
        "Simulation evidence, not IDD camera perception or RoadRunner footage."];
else
    r=data.result;log=r.log;states=unique(string({log.acargState}),'stable');
    reason=string(r.terminationReason);
    if contains(data.scenario.name,'Urban')&&data.safeTermination
        reason="SAFE PLANNING FAILURE GUARD: planner could not find a safe continuation.";
    end
    lines=["OUTCOME: "+strrep(data.outcome,'_',' '); ...
        "Goal reached: "+yesno(r.goalReached)+"     Safe termination: "+yesno(data.safeTermination)+"     Collision: "+yesno(r.collisionOccurred); ...
        sprintf('Last logged time: %.1f s | Source simulationTime: %.1f s',log(end).time,r.simulationTime); ...
        sprintf('Peak risk: %.3f | Replans: %d | Final physical speed: %.2f m/s',max([log.totalRisk]),r.numberOfReplans,log(end).egoSpeed); ...
        "States: "+strjoin(strrep(states,'_',' '),' -> '); ...
        "Recovery timestamp: "+timeText(data.recoveryTime); ...
        "Reason: "+reason;"";"A time-limit safe termination does not imply goal completion or zero physical speed."];
end
% Wrap long source descriptions/state sequences to keep every claim visible.
wrapped=strings(0,1);
for k=1:numel(lines)
    words=split(lines(k),' ');line="";
    for j=1:numel(words)
        if strlength(line)+strlength(words(j))>98,wrapped(end+1)=line;line="";end %#ok<AGROW>
        if strlength(line)>0,line=line+" ";end;line=line+words(j);
    end
    wrapped(end+1)=line; %#ok<AGROW>
end
text(ax,0,.70,strjoin(wrapped,newline),'FontSize',16,'VerticalAlignment','top', ...
    'Interpreter','none','Color',[.12 .19 .25]);
drawnow;frame=getframe(f);pixels=imresize(frame.cdata,[o.resolution(2) o.resolution(1)]);
end
function s=yesno(v)
if v,s="YES";else,s="NO";end
end
function s=timeText(v)
if isfinite(v),s=sprintf('%.1f s (source recovery criterion)',v);else,s="not reported / not applicable";end
end
