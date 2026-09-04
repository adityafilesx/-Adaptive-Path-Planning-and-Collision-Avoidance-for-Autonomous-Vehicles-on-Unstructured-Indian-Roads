function canonical = roadRunnerPoseToCanonical(rr, transformValue)
%ROADRUNNERPOSETOCANONICAL Convert RoadRunner +Y-zero pose to canonical pose.

    if nargin < 2, transformValue = []; end
    transform = resolveRoadRunnerTransform(transformValue);
    if isnumeric(rr)
        assert(isequal(size(rr), [4 4]), 'RoadRunner numeric pose must be 4-by-4.');
        pose = double(rr); position = pose(1:3,4).';
        roadHeading = atan2(pose(2,2), pose(1,2));
        velocity = [0 0 0];
    else
        if isfield(rr, 'PoseMatrix'), pose = double(rr.PoseMatrix);
        elseif isfield(rr, 'Pose'), pose = double(rr.Pose);
        else, pose = []; end
        if ~isempty(pose)
            assert(isequal(size(pose), [4 4]), 'RoadRunner Pose must be 4-by-4.');
            position = pose(1:3,4).';
            roadHeading = atan2(pose(2,2), pose(1,2));
        else
            position = double(rr.Position(:).');
            roadHeading = double(rr.Yaw) + pi/2;
        end
        if isfield(rr, 'Velocity'), velocity = double(rr.Velocity(:).');
        else, velocity = [0 0 0]; end
    end
    canonicalPosition = transform.positionRotation.' * ...
        (position(:)-transform.translation(:));
    canonicalVelocity = transform.positionRotation.' * velocity(:);
    roadForward = [cos(roadHeading); sin(roadHeading); 0];
    canonicalForward = transform.positionRotation.' * roadForward;
    yaw = atan2(canonicalForward(2), canonicalForward(1));
    canonical = struct('x', canonicalPosition(1), 'y', canonicalPosition(2), ...
        'z', canonicalPosition(3), 'yaw', yaw, ...
        'speed', hypot(canonicalVelocity(1), canonicalVelocity(2)), ...
        'Position', canonicalPosition(:).', ...
        'Velocity', canonicalVelocity(:).');
    assert(all(isfinite([canonical.Position canonical.Velocity canonical.yaw])), ...
        'Converted canonical pose/state is not finite.');
end
