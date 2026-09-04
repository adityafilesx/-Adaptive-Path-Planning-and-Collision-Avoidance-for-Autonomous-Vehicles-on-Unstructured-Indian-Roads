function rr = canonicalPoseToRoadRunner(canonical, transformValue)
%CANONICALPOSETOROADRUNNER Convert +X-zero canonical pose to RoadRunner pose.
% RoadRunner actor zero yaw faces +Y. Pose is a 4-by-4 homogeneous matrix.

    if nargin < 2, transformValue = []; end
    transform = resolveRoadRunnerTransform(transformValue);
    [position, velocity, yaw] = unpackCanonical(canonical);
    rr.Position = (transform.positionRotation * position(:) + ...
        transform.translation(:)).';
    rr.Velocity = (transform.positionRotation * velocity(:)).';
    forward = transform.positionRotation * [cos(yaw); sin(yaw); 0];
    roadHeading = atan2(forward(2), forward(1));
    rr.Yaw = wrapAngle(roadHeading - pi/2);
    c = cos(rr.Yaw); s = sin(rr.Yaw);
    rr.Pose = [c -s 0 rr.Position(1); s c 0 rr.Position(2); ...
        0 0 1 rr.Position(3); 0 0 0 1];
    rr.PoseMatrix = rr.Pose;
    rr.ReferencePoint = "actor XY center; RoadRunner asset controls vertical origin";
end

function [position, velocity, yaw] = unpackCanonical(value)
    if isnumeric(value)
        assert(numel(value) >= 3, 'Canonical numeric pose must be [x y yaw] or [x y z yaw].');
        value = double(value(:).');
        if numel(value) == 3
            position = [value(1:2) 0]; yaw = value(3);
        else
            position = value(1:3); yaw = value(4);
        end
        velocity = [0 0 0];
    else
        if isfield(value, 'Position'), position = double(value.Position(:).');
        else, position = [double(value.x) double(value.y) 0]; end
        if numel(position) == 2, position(3) = 0; end
        if isfield(value, 'Velocity')
            velocity = double(value.Velocity(:).');
        elseif isfield(value, 'speed')
            velocity = [double(value.speed)*cos(double(value.yaw)) ...
                double(value.speed)*sin(double(value.yaw)) 0];
        else
            velocity = [0 0 0];
        end
        if numel(velocity) == 2, velocity(3) = 0; end
        if isfield(value, 'yaw'), yaw = double(value.yaw);
        else, yaw = double(value.Yaw); end
    end
    assert(numel(position)==3 && numel(velocity)==3 && ...
        all(isfinite([position velocity yaw])), 'Canonical pose/state must be finite.');
end

function angle = wrapAngle(angle)
    angle = atan2(sin(angle), cos(angle));
end
