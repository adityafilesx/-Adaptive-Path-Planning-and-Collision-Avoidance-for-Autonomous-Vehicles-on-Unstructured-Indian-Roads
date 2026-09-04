function report = validateRoadRunnerEnvironment(cfg)
%VALIDATEROADRUNNERENVIRONMENT Validate configuration without side effects.

    if nargin < 1 || isempty(cfg), cfg = config(); end
    capability = isRoadRunnerAvailable(cfg);
    errors = strings(0, 1);
    if ~isfield(cfg.roadrunner, 'controlStep') || ...
            abs(cfg.roadrunner.controlStep - cfg.control.dt) > eps
        errors(end+1) = "RoadRunner controlStep must equal cfg.control.dt.";
    end
    transform = cfg.roadrunner.coordinateTransform;
    if ~isfield(transform, 'positionRotation') || ...
            ~isequal(size(transform.positionRotation), [3 3]) || ...
            any(~isfinite(transform.positionRotation), 'all') || ...
            norm(transform.positionRotation.' * transform.positionRotation-eye(3), 'fro') > 1e-10
        errors(end+1) = "coordinateTransform.positionRotation must be a finite orthonormal 3-by-3 matrix.";
    end
    if ~isfield(transform, 'translation') || numel(transform.translation) ~= 3 || ...
            any(~isfinite(transform.translation))
        errors(end+1) = "coordinateTransform.translation must contain three finite values.";
    end
    report = struct('validConfiguration', isempty(errors), ...
        'errors', errors, 'capability', capability, ...
        'runtimeCanExecute', capability.runtimeReady, ...
        'status', "ARCHITECTURE_ONLY");
    if capability.runtimeReady, report.status = "RUNTIME_READY"; end
end
