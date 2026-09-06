function [pixels,state]=renderScenarioVideoFrame(ui,data,index,o)
%RENDERSCENARIOVIDEOFRAME Extend Phase 12 presentation without changing values.
display=demoConfig();display.visible='off';display.animate=false;
display.showAdvancedExplanation=true;display.showPerformance=false;
state=updateDemoFrame(ui,data,index,display);
% A successful initial/retained plan is not a failed replan. Correct only this
% new presentation layer; preserve the original Phase 12 renderer and tests.
if state.replan&&index<numel(data.result.log)&&~state.goal
    caption=scenarioReplanCaption(data,index);
    handles=findobj(ui.panel,'Type','text');
    for k=1:numel(handles)
        if strjoin(string(handles(k).String),newline)==state.replanText
            handles(k).String=caption;
        end
    end
    state.replanText=caption;
end
% The fixed diagnostic road strip is schematic, not a drivable boundary.
right=max(105,data.scenario.goalPose(1)+12);xlim(ui.environment,[-8 right]);ylim(ui.environment,[-30 30]);
f=data.result.log(index);actors=f.actorTruth;
outside=sum(arrayfun(@(a) a.Position(1)<-8||a.Position(1)>right||abs(a.Position(2))>30,actors));
text(ui.environment,.01,.97,sprintf('%d actors | %d outside view | road strip is schematic',numel(actors),outside), ...
    'Units','normalized','VerticalAlignment','top','FontSize',9,'BackgroundColor','white','Tag','viewportNote');
if index==numel(data.result.log)&&~data.result.goalReached
    text(ui.environment,.5,.88,strrep(data.outcome,'_',' '),'Units','normalized', ...
        'HorizontalAlignment','center','FontSize',16,'FontWeight','bold','BackgroundColor','white', ...
        'Color',[.55 .33 .05],'Tag','finalOutcome');
end
setappdata(ui.figure,'displayedState',state);
drawnow;frame=getframe(ui.figure);pixels=imresize(frame.cdata,[o.resolution(2) o.resolution(1)]);
end
