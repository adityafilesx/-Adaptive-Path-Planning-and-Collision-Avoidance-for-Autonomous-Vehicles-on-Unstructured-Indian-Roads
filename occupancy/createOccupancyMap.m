function [map, metadata] = createOccupancyMap(config)
%CREATEOCCUPANCYMAP Create an empty world-frame binary occupancy map.
%   World coordinates use [x,y] = [longitudinal,lateral] in meters. The
%   returned metadata owns the map/grid conversion used by this module.

    cfg = occupancyConfig(config);
    xLimits = cfg.worldLimits(1, :);
    yLimits = cfg.worldLimits(2, :);
    width = diff(xLimits);
    height = diff(yLimits);
    map = binaryOccupancyMap(width, height, cfg.resolution);
    map.GridLocationInWorld = [xLimits(1), yLimits(1)];

    columnCount = round(width * cfg.resolution);
    rowCount = round(height * cfg.resolution);
    metadata = struct('Resolution', cfg.resolution, 'CellSize', cfg.cellSize, ...
        'WorldLimits', cfg.worldLimits, 'Origin', [xLimits(1), yLimits(1)], ...
        'GridSize', [rowCount, columnCount], ...
        'XCenters', xLimits(1) + ((0:columnCount - 1) + 0.5) / cfg.resolution, ...
        'YCenters', yLimits(1) + ((0:rowCount - 1) + 0.5) / cfg.resolution, ...
        'CoordinateConvention', '[x,y] = [longitudinal,lateral] world meters');
end

function cfg = occupancyConfig(config)
    if isfield(config, 'occupancy')
        cfg = config.occupancy;
    else
        cfg = config;
    end
    required = {'cellSize', 'resolution', 'worldLimits'};
    for index = 1:numel(required)
        if ~isfield(cfg, required{index})
            error('createOccupancyMap:MissingConfiguration', ...
                'Missing occupancy configuration field: %s.', required{index});
        end
    end
    if ~isscalar(cfg.resolution) || cfg.resolution <= 0 || ...
            ~isscalar(cfg.cellSize) || cfg.cellSize <= 0 || ...
            ~isequal(size(cfg.worldLimits), [2 2]) || ...
            any(diff(cfg.worldLimits, 1, 2) <= 0)
        error('createOccupancyMap:InvalidConfiguration', ...
            'Map resolution, cell size, or world limits are invalid.');
    end
end
