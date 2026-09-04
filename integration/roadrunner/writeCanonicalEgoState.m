function result = writeCanonicalEgoState(rrSimulation, ego, manifest)
%WRITECANONICALEGOSTATE Write MATLAB-authoritative pose/velocity to ego actor.

    result = struct('written', false, 'status', "FAIL", 'message', "", ...
        'runtimeAPICalls', 0, 'roadRunnerState', struct());
    rrState = canonicalEgoToRoadRunner(ego, manifest);
    result.roadRunnerState = rrState;
    try
        actorSims = get(rrSimulation, "ActorSimulation");
        egoActor = [];
        for i = 1:numel(actorSims)
            if actorMatches(actorSims(i), string(manifest.egoActorName))
                egoActor = actorSims(i); break;
            end
        end
        if isempty(egoActor)
            result.message = "RoadRunner ego actor was not found by manifest name.";
            return;
        end
        result.runtimeAPICalls = result.runtimeAPICalls + 2;
        setAttribute(egoActor, Pose=rrState.Pose);
        setAttribute(egoActor, Velocity=rrState.Velocity);
        result.written = true; result.status = "PASS";
        result.message = "Canonical ego pose and velocity written to RoadRunner.";
    catch info
        result.message = "RoadRunner ego write failed: " + string(info.message);
    end
end

function yes = actorMatches(actorSim, expectedName)
yes = false;
try
    yes = strcmpi(string(get(actorSim,"Name")), expectedName);
catch
    try
        value=convertToStruct(actorSim);
        yes=isfield(value,'Name') && strcmpi(string(value.Name),expectedName);
    catch
    end
end
end
