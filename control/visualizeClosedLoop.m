function visualizeClosedLoop(result, demo)
%VISUALIZECLOSEDLOOP Show final environment, trajectory, path, and risk history.

    figure('Name', 'Phase 7 Closed-Loop Simulation', ...
        'Position', [80 80 1250 520]);
    subplot(1, 2, 1);
    show(result.latestPlanner.ValidationMap);
    hold on;
    plot(result.egoHistory(:, 1), result.egoHistory(:, 2), 'b-', ...
        'LineWidth', 2, 'DisplayName', 'Ego trajectory');
    plot(demo.goalPose(1), demo.goalPose(2), 'gp', 'MarkerSize', 12, ...
        'MarkerFaceColor', 'g', 'DisplayName', 'Goal');
    for i = 1:size(result.actorHistory, 1)
        trajectory = squeeze(result.actorHistory(i, 1:2, :)).';
        plot(trajectory(:, 1), trajectory(:, 2), 'r--', ...
            'LineWidth', 1.5, 'DisplayName', 'Actor trajectory');
        plot(trajectory(end, 1), trajectory(end, 2), 'ro', ...
            'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
    end
    if result.activePath.success
        plot(result.activePath.states(:, 1), result.activePath.states(:, 2), ...
            'm-', 'LineWidth', 1.2, 'DisplayName', 'Final active path');
    end
    title(sprintf('Closed loop: %s', result.terminationReason));
    xlabel('x (m)'); ylabel('y (m)'); axis equal; legend('Location', 'best');

    subplot(1, 2, 2);
    times = [result.log.time];
    yyaxis left;
    plot(times, [result.log.egoSpeed], 'b-', 'LineWidth', 1.5);
    hold on;
    plot(times, [result.log.desiredSpeed], 'c--', 'LineWidth', 1.2);
    ylabel('Speed (m/s)');
    yyaxis right;
    plot(times, [result.log.totalRisk], 'r-', 'LineWidth', 1.5);
    ylabel('Total risk'); ylim([0 1]);
    xlabel('Time (s)'); grid on;
    title('Physical speed response and recomputed risk');
    legend('Ego speed', 'Desired speed', 'Total risk', 'Location', 'best');
end
