function visualizeOccupancy(riskMap, egoState, tracks)
%VISUALIZEOCCUPANCY Display conservative normalized risk and actor corridors.
%   This helper needs only the standalone map representation, not
%   drivingScenario or Automated Driving Toolbox.

    metadata = riskMap.metadata;
    figure('Name', 'SIH26037 Phase 4 Dynamic Occupancy / Risk', ...
        'Position', [120 120 900 620]);
    imagesc(metadata.XCenters, metadata.YCenters, riskMap.conservativeRiskGrid);
    axis xy equal tight;
    colormap(parula);
    colorbar;
    caxis([0 1]);
    hold on;
    xlabel('Longitudinal x (m)');
    ylabel('Lateral y (m)');
    title('Phase 4: Conservative Dynamic Occupancy and Normalized Risk');

    egoPosition = readPosition(egoState);
    plot(egoPosition(1), egoPosition(2), 'kp', 'MarkerSize', 12, ...
        'MarkerFaceColor', 'y', 'DisplayName', 'Ego');
    for index = 1:numel(tracks)
        state = readField(tracks(index), {'CurrentState'}, []);
        if numel(state) >= 2 && all(isfinite(state(1:2)))
            plot(state(1), state(2), 'wo', 'MarkerSize', 7, ...
                'LineWidth', 1.3, 'DisplayName', 'Tracked actor');
        end
    end
    for index = 1:numel(riskMap.actorPredictions)
        prediction = riskMap.actorPredictions{index}.Prediction;
        plot(prediction.Position(:, 1), prediction.Position(:, 2), 'w--', ...
            'LineWidth', 1.2, 'HandleVisibility', 'off');
    end
    legend('Location', 'best');
end

function position = readPosition(egoState)
    position = readField(egoState, {'Position', 'CurrentState'}, [0 0]);
    position = double(position(:).');
    if numel(position) < 2 || any(~isfinite(position(1:2)))
        position = [0 0];
    else
        position = position(1:2);
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
