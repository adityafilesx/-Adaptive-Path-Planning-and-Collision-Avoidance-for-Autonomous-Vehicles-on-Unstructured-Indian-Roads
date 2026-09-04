function transform = resolveRoadRunnerTransform(value)
%RESOLVEROADRUNNERTRANSFORM Normalize a configured/manifest frame transform.

    transform = struct('positionRotation', eye(3), 'translation', [0 0 0]);
    if nargin < 1 || isempty(value), return; end
    if isfield(value, 'coordinateTransform'), value = value.coordinateTransform; end
    if isfield(value, 'positionRotation')
        rotation = double(value.positionRotation);
        if isvector(rotation) && numel(rotation) == 9
            rotation = reshape(rotation, 3, 3).';
        end
        transform.positionRotation = rotation;
    end
    if isfield(value, 'translation')
        transform.translation = double(value.translation(:).');
    end
    if ~isequal(size(transform.positionRotation), [3 3]) || ...
            any(~isfinite(transform.positionRotation), 'all') || ...
            norm(transform.positionRotation.'*transform.positionRotation-eye(3),'fro') > 1e-10
        error('RoadRunner:InvalidTransform', ...
            'positionRotation must be a finite orthonormal 3-by-3 matrix.');
    end
    if numel(transform.translation) ~= 3 || any(~isfinite(transform.translation))
        error('RoadRunner:InvalidTransform', ...
            'translation must contain three finite values.');
    end
end
