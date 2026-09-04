function metrics = computePathMetrics(states, validationMap, config)
%COMPUTEPATHMETRICS Measure native Hybrid A* path geometry and map clearance.
%   pathSmoothness is the mean absolute change in segment curvature. Clearance
%   is grid-resolution-limited distance to occupied cells in validationMap.

    cfg = config.planning;
    metrics = struct('pathLength', 0, 'pathSmoothness', 0, ...
        'minimumClearance', 0);
    if size(states, 1) < 2
        return;
    end
    segmentVectors = diff(states(:, 1:2), 1, 1);
    segmentLengths = hypot(segmentVectors(:, 1), segmentVectors(:, 2));
    metrics.pathLength = sum(segmentLengths);
    headingChange = wrapAngle(diff(states(:, 3)));
    nonzeroSegments = segmentLengths > eps;
    curvature = headingChange(nonzeroSegments) ./ segmentLengths(nonzeroSegments);
    if numel(curvature) > 1
        metrics.pathSmoothness = mean(abs(diff(curvature)));
    end
    metrics.minimumClearance = mapClearance(states(:, 1:2), validationMap, ...
        cfg.maximumReportedClearance);
end

function angle = wrapAngle(angle)
    angle = mod(angle + pi, 2 * pi) - pi;
end

function clearance = mapClearance(pathXY, map, maximumReportedClearance)
    occupied = occupancyMatrix(map);
    [rows, columns] = find(occupied);
    if isempty(rows)
        clearance = maximumReportedClearance;
        return;
    end
    resolution = map.Resolution;
    x = map.XWorldLimits(1) + (columns - 0.5) / resolution;
    y = map.YWorldLimits(1) + (rows - 0.5) / resolution;
    occupiedXY = [x, y];
    clearance = maximumReportedClearance;
    for index = 1:size(pathXY, 1)
        distances = hypot(occupiedXY(:, 1) - pathXY(index, 1), ...
            occupiedXY(:, 2) - pathXY(index, 2));
        clearance = min(clearance, min(distances));
    end
    clearance = max(0, clearance);
end
