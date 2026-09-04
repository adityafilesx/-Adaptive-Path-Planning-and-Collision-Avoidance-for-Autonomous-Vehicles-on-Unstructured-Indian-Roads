function risk = computeDistanceRisk(actorPos, egoPos, cfg)
%COMPUTEDISTANCERISK Normalised proximity risk based on Euclidean distance.
%   Closer actors produce higher risk using exponential decay:
%       D = exp(-distance / distanceDecayScale)
%
%   Output: risk ∈ [0,1]   (1 = on top of ego, 0 = far away)

    gcfg = governorSubConfig(cfg, 'risk');

    actorXY = safeVec2(actorPos);
    egoXY   = safeVec2(egoPos);
    d = norm(actorXY - egoXY);

    if ~isfinite(d) || d < 0
        risk = 0;
        return;
    end

    risk = exp(-d / gcfg.distanceDecayScale);
    risk = min(1, max(0, risk));
end

%% ---- local helpers ----

function gcfg = governorSubConfig(cfg, subField)
    if isfield(cfg, 'governor') && isfield(cfg.governor, subField)
        gcfg = cfg.governor.(subField);
    else
        error('computeDistanceRisk:MissingConfig', ...
            'cfg.governor.%s is required.', subField);
    end
end

function vec = safeVec2(value)
    value = double(value(:).');
    if numel(value) < 2
        vec = [0 0];
    else
        vec = value(1:2);
    end
    vec(~isfinite(vec)) = 0;
end
