function score = computeUncertaintyScore(track, cfg)
%COMPUTEUNCERTAINTYSCORE Normalised position-uncertainty score for a track.
%   Uses the position-covariance block from the Phase 3 track's
%   CurrentCovariance.  Higher trace → higher uncertainty.
%
%   Output: score ∈ [0,1]   (higher = more uncertain)

    gcfg = governorSubConfig(cfg, 'uncertainty');

    covariance = readField(track, {'CurrentCovariance'}, []);
    if ~isequal(size(covariance), [4 4]) || any(~isfinite(covariance(:)))
        score = 1.0;   % unknown covariance → maximum uncertainty
        return;
    end

    posTrace = trace(covariance(1:2, 1:2));
    if ~isfinite(posTrace) || posTrace < 0
        score = 1.0;
        return;
    end

    score = min(1, posTrace / gcfg.varianceScale);
end

%% ---- local helpers ----

function gcfg = governorSubConfig(cfg, subField)
    if isfield(cfg, 'governor') && isfield(cfg.governor, subField)
        gcfg = cfg.governor.(subField);
    else
        error('computeUncertaintyScore:MissingConfig', ...
            'cfg.governor.%s is required.', subField);
    end
end

function value = readField(item, names, fallback)
    value = fallback;
    for index = 1:numel(names)
        if isstruct(item) && isfield(item, names{index})
            value = item.(names{index});
            return;
        end
    end
end
