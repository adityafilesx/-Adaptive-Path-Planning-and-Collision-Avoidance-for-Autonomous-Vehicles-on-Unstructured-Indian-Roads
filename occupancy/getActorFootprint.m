function footprint = getActorFootprint(actorClass, config)
%GETACTORFOOTPRINT Return configurable simulation footprint parameters.
%   Dimensions are engineering inputs for map inflation, not manufacturer
%   specifications or scientifically calibrated safety claims.

    cfg = occupancyConfig(config);
    key = classKey(actorClass, cfg.classIDMap);
    if isfield(cfg.footprints, key)
        parameters = cfg.footprints.(key);
    else
        parameters = cfg.footprints.default;
        key = 'default';
    end
    footprint = parameters;
    footprint.ClassKey = key;
end

function cfg = occupancyConfig(config)
    if isfield(config, 'occupancy')
        cfg = config.occupancy;
    else
        cfg = config;
    end
    if ~isfield(cfg, 'footprints') || ~isfield(cfg.footprints, 'default')
        error('getActorFootprint:MissingConfiguration', ...
            'Occupancy footprint parameters are required.');
    end
    if ~isfield(cfg, 'classIDMap')
        cfg.classIDMap = struct();
    end
end

function key = classKey(value, classIDMap)
    if isnumeric(value) && isscalar(value) && isfinite(value)
        numericKey = sprintf('id%d', value);
        if isfield(classIDMap, numericKey)
            value = classIDMap.(numericKey);
        else
            key = 'default';
            return;
        end
    end
    if isstring(value)
        value = char(value);
    end
    if ~ischar(value)
        key = 'default';
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
        key = 'default';
    end
end
