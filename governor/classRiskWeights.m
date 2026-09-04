function weight = classRiskWeights(perceivedClass, cfg)
%CLASSRISKWEIGHTS Normalised class-dependent risk weight for an actor.
%   Raw engineering weights are stored in cfg.governor.classWeights.
%   The function normalises internally relative to the car baseline so
%   that car = 1.0 and more unpredictable classes score proportionally
%   higher.  These are engineering priors, NOT IDD-derived values.
%
%   Output: weight >= 0  (normalised relative to car)

    gcfg = governorSubConfig(cfg, 'classWeights');
    key  = classKey(perceivedClass);

    if isfield(gcfg, key)
        raw = gcfg.(key);
    elseif isfield(gcfg, 'unknown')
        raw = gcfg.unknown;
    elseif isfield(gcfg, 'default')
        raw = gcfg.default;
    else
        raw = 1.0;
    end

    % Normalise relative to car baseline
    if isfield(gcfg, 'car') && gcfg.car > 0
        baseline = gcfg.car;
    else
        baseline = 1.0;
    end

    weight = max(0, raw / baseline);
end

%% ---- local helpers ----

function gcfg = governorSubConfig(cfg, subField)
    if isfield(cfg, 'governor') && isfield(cfg.governor, subField)
        gcfg = cfg.governor.(subField);
    else
        error('classRiskWeights:MissingConfig', ...
            'cfg.governor.%s is required.', subField);
    end
end

function key = classKey(value)
    if isstring(value)
        value = char(value);
    end
    if ~ischar(value) || isempty(value)
        key = 'unknown';
        return;
    end
    key = lower(regexprep(value, '[^a-zA-Z0-9_]', '_'));
    if strcmp(key, 'two_wheeler') || strcmp(key, 'twowheeler')
        key = 'two_wheeler';
    elseif strcmp(key, 'auto_rickshaw') || strcmp(key, 'autorickshaw')
        key = 'auto';
    elseif strcmp(key, 'cattle_animal')
        key = 'cattle';
    elseif isempty(key)
        key = 'unknown';
    end
end
