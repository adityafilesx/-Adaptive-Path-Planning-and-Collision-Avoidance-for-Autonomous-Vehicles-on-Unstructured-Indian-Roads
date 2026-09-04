function rrState = canonicalEgoToRoadRunner(ego, manifestOrTransform)
%CANONICALEGOTOROADRUNNER Expose only canonical ego pose/state to bridge.

    if nargin < 2, manifestOrTransform = []; end
    rrState = canonicalPoseToRoadRunner(ego, manifestOrTransform);
    rrState.ActorName = "EgoVehicle";
    if isstruct(manifestOrTransform) && isfield(manifestOrTransform, 'egoActorName')
        rrState.ActorName = string(manifestOrTransform.egoActorName);
    end
    rrState.Speed = double(ego.speed);
    rrState.Source = "validated MATLAB kinematic bicycle state";
end
