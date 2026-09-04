function detections = applyPhase9DetectionSchedule(detections, currentTime, schedule)
%APPLYPHASE9DETECTIONSCHEDULE Inject deterministic sensor-quality intervals.

    for eventIndex = 1:numel(schedule)
        event = schedule(eventIndex);
        if currentTime + eps < event.StartTime || currentTime - eps > event.EndTime
            continue;
        end
        detectionIndex = find([detections.ID] == event.ActorID, 1);
        if isempty(detectionIndex)
            continue;
        end
        if isfield(event, 'IsDetected') && ~event.IsDetected
            detections(detectionIndex).IsDetected = false;
            detections(detectionIndex).Confidence = 0;
            detections(detectionIndex).Position(:) = NaN;
            detections(detectionIndex).Velocity(:) = NaN;
        else
            if isfield(event, 'Confidence') && isfinite(event.Confidence)
                detections(detectionIndex).Confidence = event.Confidence;
            end
            if isfield(event, 'PositionStd') && ~isempty(event.PositionStd)
                value = double(event.PositionStd(:).');
                detections(detectionIndex).PositionStd = value(1:3);
            end
            if isfield(event, 'VelocityStd') && ~isempty(event.VelocityStd)
                value = double(event.VelocityStd(:).');
                detections(detectionIndex).VelocityStd = value(1:3);
            end
        end
    end
end
