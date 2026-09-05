function events = buildDemoEvents(result)
%BUILDDEMOEVENTS Derive transition and control events from actual logs.
rows=struct('Time',{},'Type',{},'Description',{}); log=result.log;
for i=1:numel(log)
    f=log(i);
    if i>1 && ~strcmp(f.acargState,log(i-1).acargState)
        add('STATE',sprintf('%s > %s',log(i-1).acargState,f.acargState));
        if strcmp(log(i-1).acargState,'CONSERVATIVE_STOP') || strcmp(f.acargState,'NORMAL')
            add('RECOVERY','Governor relaxes after risk falls');
        end
    end
    if f.plannerInvoked
        if f.planningSucceeded,label='PATH UPDATED';else,label='PLAN FAILED';end
        add('REPLAN',sprintf('%s: %s',label,strjoin(f.replanReasons,' / ')));
    end
    if ~f.pathSafe && (i==1 || log(i-1).pathSafe),add('PATH','Path unsafe; braking commanded');end
    if f.desiredSpeed==0 && i>1 && log(i-1).desiredSpeed>0,add('STOP','Zero target speed commanded');end
end
if result.goalReached,add('GOAL','Goal reached');end
if result.collisionOccurred,add('COLLISION','Collision detected');end
events=struct2table(rows);
    function add(kind,description)
        rows(end+1)=struct('Time',f.time,'Type',string(kind),'Description',string(description));
    end
end
