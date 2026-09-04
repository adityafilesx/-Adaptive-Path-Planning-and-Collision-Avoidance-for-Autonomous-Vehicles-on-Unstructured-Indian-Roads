function [tracks, detections] = updateActorTracks(tracks, actorTruth, ...
        egoState, currentTime, cfg, detectionModifierFcn)
%UPDATEACTORTRACKS Run perception and persistent Phase 3 tracking for a frame.

    detections = simulatePerception(actorTruth, egoState, cfg);
    if nargin >= 6 && ~isempty(detectionModifierFcn)
        detections = detectionModifierFcn( ...
            detections, currentTime, actorTruth, egoState, cfg);
    end
    for i = 1:numel(detections)
        detection = detections(i);
        index = findTrack(tracks, detection.ID);
        if isempty(index)
            if detection.IsDetected
                newTrack = initializeTracker(detection, cfg.control.dt, ...
                    cfg, currentTime);
                if isempty(tracks)
                    tracks = newTrack;
                else
                    tracks(end + 1, 1) = newTrack; %#ok<AGROW>
                end
            end
        else
            tracks(index) = updateTracker(tracks(index), detection, ...
                cfg.control.dt, cfg, currentTime);
        end
    end
end

function index = findTrack(tracks, actorID)
    index = [];
    for i = 1:numel(tracks)
        if isequal(tracks(i).ActorID, actorID)
            index = i;
            return;
        end
    end
end
