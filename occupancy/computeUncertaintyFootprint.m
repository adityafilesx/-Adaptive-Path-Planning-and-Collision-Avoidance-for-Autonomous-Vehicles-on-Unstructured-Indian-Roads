function envelope = computeUncertaintyFootprint(actorState, covariance, actorClass, config)
%COMPUTEUNCERTAINTYFOOTPRINT Combine physical footprint and covariance ellipse.
%   Invalid covariance falls back to a configurable conservative variance.

    cfg = occupancyConfig(config);
    footprint = getActorFootprint(actorClass, cfg);
    positionCovariance = positionCovarianceOf(covariance, cfg.invalidCovarianceVariance);
    [vectors, values] = eig(positionCovariance);
    eigenvalues = max(0, real(diag(values)));
    [eigenvalues, order] = sort(eigenvalues, 'descend');
    vectors = real(vectors(:, order));
    uncertaintyAxes = cfg.uncertaintyKSigma * sqrt(eigenvalues(:).');
    physicalAxes = [footprint.Length / 2, footprint.Width / 2] + ...
        footprint.SafetyMargin;
    semiAxes = max(cfg.minimumEllipseAxis, physicalAxes + uncertaintyAxes);
    orientation = atan2(vectors(2, 1), vectors(1, 1));
    state = actorState(:);
    if numel(state) < 2 || any(~isfinite(state(1:2)))
        error('computeUncertaintyFootprint:InvalidState', ...
            'Actor state must include a finite [x;y] position.');
    end
    envelope = struct('Center', state(1:2).', 'SemiAxes', semiAxes, ...
        'Orientation', orientation, 'PositionCovariance', positionCovariance, ...
        'UncertaintyAxes', uncertaintyAxes, 'PhysicalFootprint', footprint);
end

function cfg = occupancyConfig(config)
    if isfield(config, 'occupancy')
        cfg = config.occupancy;
    else
        cfg = config;
    end
    required = {'uncertaintyKSigma', 'invalidCovarianceVariance', ...
        'minimumEllipseAxis'};
    for index = 1:numel(required)
        if ~isfield(cfg, required{index})
            error('computeUncertaintyFootprint:MissingConfiguration', ...
                'Missing occupancy configuration field: %s.', required{index});
        end
    end
end

function value = positionCovarianceOf(covariance, fallbackVariance)
    if isequal(size(covariance), [4 4])
        value = covariance(1:2, 1:2);
    elseif isequal(size(covariance), [2 2])
        value = covariance;
    else
        value = NaN(2);
    end
    if any(~isfinite(value(:)))
        value = fallbackVariance * eye(2);
    else
        value = (value + value.') / 2;
        [vectors, values] = eig(value);
        values = max(0, real(diag(values)));
        value = real(vectors * diag(values) * vectors.');
    end
end
