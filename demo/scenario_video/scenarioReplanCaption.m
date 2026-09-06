function caption=scenarioReplanCaption(data,index)
%SCENARIOREPLANCAPTION Describe success and actual current command separately.
log=data.result.log;f=log(index);
recent=find([log(1:index).plannerInvoked]&f.time-[log(1:index).time]<=.8+eps,1,'last');
caption="";if isempty(recent),return;end
event=log(recent);
if event.planningSucceeded
    if event.pathReplaced,caption="PATH UPDATED";
    elseif recent==1,caption="INITIAL PLAN READY";
    else,caption="PLAN READY | SAFE PATH RETAINED";end
elseif f.pathSafe&&f.desiredSpeed>0
    caption="PLAN FAILED | SAFE PATH RETAINED";
else
    caption="PLAN FAILED | ZERO TARGET SPEED";
end
caption=caption+newline+strjoin(string(event.replanReasons),', ');
end
