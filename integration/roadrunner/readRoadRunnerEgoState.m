function [ego, result] = readRoadRunnerEgoState(rrSimulation, manifest)
%READROADRUNNEREGOSTATE Read back ego through the canonical pose boundary.

    ego=struct();
    result=struct('read',false,'status',"FAIL",'message',"",'runtimeAPICalls',0);
    try
        actorSims=get(rrSimulation,"ActorSimulation"); egoActor=[];
        for i=1:numel(actorSims)
            if actorMatches(actorSims(i),string(manifest.egoActorName))
                egoActor=actorSims(i); break;
            end
        end
        if isempty(egoActor)
            result.message="RoadRunner ego actor was not found by manifest name."; return;
        end
        result.runtimeAPICalls=2;
        native=struct('Pose',double(getAttribute(egoActor,"Pose")), ...
            'Velocity',double(getAttribute(egoActor,"Velocity")));
        ego=roadRunnerPoseToCanonical(native,manifest);
        result.read=true; result.status="PASS";
        result.message="RoadRunner ego pose and velocity read in canonical coordinates.";
    catch info
        result.message="RoadRunner ego read failed: "+string(info.message);
    end
end

function yes=actorMatches(actorSim,expectedName)
yes=false;
try
    yes=strcmpi(string(get(actorSim,"Name")),expectedName);
catch
    try
        value=convertToStruct(actorSim);
        yes=isfield(value,'Name')&&strcmpi(string(value.Name),expectedName);
    catch
    end
end
end
