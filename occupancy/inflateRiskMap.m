function [map, riskGrid, mask] = inflateRiskMap(map, riskGrid, envelope, ...
        riskContribution, metadata)
%INFLATERISKMAP Rasterize an uncertainty-aware actor footprint into a layer.
%   The binary map records occupied cells; riskGrid stores normalized risk,
%   taking the maximum contribution when multiple actors overlap.

    if ~isequal(size(riskGrid), metadata.GridSize)
        error('inflateRiskMap:InvalidRiskGrid', ...
            'riskGrid must match the occupancy metadata grid size.');
    end
    if ~isscalar(riskContribution) || ~isfinite(riskContribution)
        error('inflateRiskMap:InvalidRisk', 'Risk contribution must be finite.');
    end
    [xGrid, yGrid] = meshgrid(metadata.XCenters, metadata.YCenters);
    deltaX = xGrid - envelope.Center(1);
    deltaY = yGrid - envelope.Center(2);
    cosine = cos(envelope.Orientation);
    sine = sin(envelope.Orientation);
    localX = cosine * deltaX + sine * deltaY;
    localY = -sine * deltaX + cosine * deltaY;
    mask = (localX ./ envelope.SemiAxes(1)).^2 + ...
        (localY ./ envelope.SemiAxes(2)).^2 <= 1;
    if ~any(mask(:))
        return;
    end
    riskGrid(mask) = max(riskGrid(mask), min(1, max(0, riskContribution)));
    occupiedPoints = [xGrid(mask), yGrid(mask)];
    setOccupancy(map, occupiedPoints, true(size(occupiedPoints, 1), 1));
end
