function visualizePlan(plannerData, pathData, config)
%VISUALIZEPLAN Show vehicle-inflated occupancy, poses, and Hybrid A* path.

    cfg = config.visualization;
    figure('Name', 'SIH26037 Phase 5 Hybrid A* Plan', ...
        'Position', [120 120 920 620]);
    show(plannerData.ValidationMap);
    hold on;
    title('Phase 5: Vehicle-Aware Hybrid A* on Conservative Occupancy');
    xlabel('Longitudinal x (m)');
    ylabel('Lateral y (m)');
    startPose = pathData.startPose;
    goalPose = pathData.goalPose;
    plot(startPose(1), startPose(2), 'go', 'MarkerFaceColor', 'g', ...
        'MarkerSize', 8, 'DisplayName', 'Start');
    plot(goalPose(1), goalPose(2), 'rp', 'MarkerFaceColor', 'r', ...
        'MarkerSize', 10, 'DisplayName', 'Goal');
    if pathData.success
        plot(pathData.x, pathData.y, 'b-', 'LineWidth', 2, ...
            'DisplayName', 'Hybrid A* path');
        if cfg.showHeading
            quiver(pathData.x, pathData.y, cos(pathData.theta), ...
                sin(pathData.theta), 0.7, 'b', 'HandleVisibility', 'off');
        end
        if cfg.showVehicleFootprint
            indices = unique([1:cfg.vehicleFootprintStride:numel(pathData.x), ...
                numel(pathData.x)]);
            for index = indices
                drawVehicleFootprint(pathData.states(index, :), plannerData, ...
                    'b', 0.12);
            end
        end
    end
    legend('Location', 'best');
    axis equal;
    hold off;
end

function drawVehicleFootprint(pose, plannerData, color, alpha)
    length = plannerData.VehicleLength;
    width = plannerData.VehicleWidth;
    localCorners = [length/2 width/2; length/2 -width/2; ...
        -length/2 -width/2; -length/2 width/2];
    rotation = [cos(pose(3)) -sin(pose(3)); sin(pose(3)) cos(pose(3))];
    corners = (rotation * localCorners.').';
    corners = corners + pose(1:2);
    patch(corners(:, 1), corners(:, 2), color, 'FaceAlpha', alpha, ...
        'EdgeColor', color, 'HandleVisibility', 'off');
end
