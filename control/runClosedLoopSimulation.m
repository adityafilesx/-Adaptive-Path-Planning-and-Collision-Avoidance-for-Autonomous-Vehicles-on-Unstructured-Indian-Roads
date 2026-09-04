function result = runClosedLoopSimulation(demo)
%RUNCLOSEDLOOPSIMULATION Execute the Phase 2–7 feedback pipeline.

    cfg = demo.config;
    rng(cfg.control.randomSeed, 'twister');
    ego = demo.egoState;
    actors = demo.actors;
    tracks = struct([]);
    activePath = emptyActivePath();
    latestPlanner = [];
    latestRiskMap = [];
    latestAdaptiveMap = [];
    previousACARG = [];
    currentTime = 0;
    lastPlanTime = -inf;
    distanceTravelled = 0;
    numberOfReplans = 0;
    numberOfFailedReplans = 0;
    consecutivePlanningFailures = 0;
    initialPathLength = NaN;
    planEvents = emptyPlanEvents();
    logEntries = emptyLog();
    egoHistory = [ego.x ego.y ego.yaw ego.speed];
    actorHistory = reshape([actors.Position], 3, []).';
    goalReached = false;
    collisionOccurred = false;
    terminationReason = 'Maximum simulation time reached safely.';

    while currentTime <= cfg.control.maxSimulationTime + eps
        if isfield(demo, 'actorUpdateFcn') && ~isempty(demo.actorUpdateFcn)
            actors = demo.actorUpdateFcn(actors, currentTime);
        end
        detectionModifierFcn = [];
        if isfield(demo, 'detectionModifierFcn')
            detectionModifierFcn = demo.detectionModifierFcn;
        end
        [tracks, detections] = updateActorTracks(tracks, actors, ego, ...
            currentTime, cfg, detectionModifierFcn);
        latestRiskMap = updateOccupancyMap(tracks, ego, cfg);
        acarg = acargGovernor(tracks, ego, cfg, previousACARG);
        latestAdaptiveMap = applyAdaptiveSafetyEnvelope(latestRiskMap, acarg, cfg);
        latestPlanner = createPlanner(latestAdaptiveMap, cfg);
        currentPose = [ego.x ego.y ego.yaw];
        [replanNow, replanReasons, pathSafeBefore] = shouldReplan( ...
            activePath, latestPlanner, currentPose, lastPlanTime, ...
            currentTime, acarg, previousACARG, cfg);

        plannerInvoked = false;
        planningSucceeded = false;
        pathReplaced = false;
        if replanNow
            plannerInvoked = true;
            oldPath = activePath;
            planningTimer = tic;
            candidate = planPath(latestPlanner, currentPose, ...
                demo.goalPose, cfg);
            planningLatency = toc(planningTimer);
            lastPlanTime = currentTime;
            if candidate.success
                planningSucceeded = true;
                consecutivePlanningFailures = 0;
                isInitial = ~oldPath.success;
                pathReplaced = ~isInitial && pathsDiffer(oldPath, candidate, cfg);
                activePath = candidate;
                if isInitial
                    initialPathLength = candidate.length;
                else
                    numberOfReplans = numberOfReplans + 1;
                end
                planEvents(end + 1, 1) = makePlanEvent(currentTime, true, ...
                    isInitial, pathReplaced, oldPath, candidate, replanReasons, ...
                    planningLatency); %#ok<AGROW>
            else
                numberOfFailedReplans = numberOfFailedReplans + 1;
                consecutivePlanningFailures = consecutivePlanningFailures + 1;
                planEvents(end + 1, 1) = makePlanEvent(currentTime, false, ...
                    ~oldPath.success, false, oldPath, candidate, replanReasons, ...
                    planningLatency); %#ok<AGROW>
                if ~pathSafeBefore
                    activePath = emptyActivePath();
                end
            end
        end

        if activePath.success
            pathSafe = isPathSafe(activePath, latestPlanner, currentPose, cfg);
        else
            pathSafe = false;
        end
        desiredSpeed = desiredSpeedForACARG(acarg, cfg);
        if ~pathSafe
            desiredSpeed = 0;
            steering = 0;
        else
            steering = followPath(ego, activePath, cfg);
        end
        acceleration = cfg.control.speedControlGain * (desiredSpeed - ego.speed);
        acceleration = min(cfg.control.maxAcceleration, ...
            max(-cfg.control.maxDeceleration, acceleration));
        [collisionNow, minimumActorDistance] = checkCollision(ego, actors, cfg);
        collisionOccurred = collisionOccurred || collisionNow;
        [goalNow, goalDistance] = checkGoalReached(ego, demo.goalPose, cfg);

        logEntries(end + 1, 1) = makeLogEntry(currentTime, ego, ...
            desiredSpeed, steering, acceleration, acarg, plannerInvoked, ...
            planningSucceeded, pathReplaced, pathSafe, activePath, ...
            minimumActorDistance, detections, tracks, actors, ...
            replanReasons, pathSafeBefore, latestAdaptiveMap); %#ok<AGROW>

        if collisionOccurred
            terminationReason = 'Collision detected.';
            break;
        end
        if goalNow
            goalReached = true;
            terminationReason = 'Goal reached.';
            break;
        end
        if currentTime >= cfg.control.maxSimulationTime
            break;
        end
        if consecutivePlanningFailures >= ...
                cfg.control.maxConsecutivePlanningFailures && ~pathSafe
            terminationReason = 'Safely stopped after repeated planning failures.';
            break;
        end

        previousACARG = acarg;
        previousPosition = [ego.x ego.y];
        [ego, ~] = updateEgoState(ego, steering, desiredSpeed, cfg);
        distanceTravelled = distanceTravelled + norm([ego.x ego.y] - previousPosition);
        actors = advanceDynamicActors(actors, cfg.control.dt);
        currentTime = currentTime + cfg.control.dt;
        egoHistory(end + 1, :) = [ego.x ego.y ego.yaw ego.speed]; %#ok<AGROW>
        actorHistory(:, :, size(actorHistory, 3) + 1) = ...
            reshape([actors.Position], 3, []).';
    end

    result = struct('goalReached', goalReached, ...
        'collisionOccurred', collisionOccurred, ...
        'simulationTime', currentTime, 'distanceTravelled', distanceTravelled, ...
        'numberOfReplans', numberOfReplans, ...
        'numberOfFailedReplans', numberOfFailedReplans, ...
        'initialPathLength', initialPathLength, 'activePath', activePath, ...
        'planEvents', planEvents, 'log', logEntries, ...
        'egoHistory', egoHistory, 'actorHistory', actorHistory, ...
        'finalEgoState', ego, 'finalActors', actors, 'tracks', tracks, ...
        'latestRiskMap', latestRiskMap, 'latestAdaptiveRiskMap', latestAdaptiveMap, ...
        'latestPlanner', latestPlanner, 'terminationReason', terminationReason, ...
        'goalDistanceError', goalDistance);
    result.metrics = summarizeClosedLoop(logEntries, result, cfg);
end

function path = emptyActivePath()
    path = struct('success', false, 'states', zeros(0, 3), ...
        'length', 0, 'failureReason', 'No active path.');
end

function events = emptyPlanEvents()
    events = repmat(struct('time', 0, 'success', false, 'initialPlan', false, ...
        'pathReplaced', false, 'oldLength', 0, 'newLength', 0, ...
        'oldMaximumLateralDeviation', 0, 'newMaximumLateralDeviation', 0, ...
        'latencySeconds', 0, 'reasons', {{}}, 'failureReason', ''), 0, 1);
end

function event = makePlanEvent(time, success, initial, replaced, oldPath, ...
        newPath, reasons, latency)
    event = struct('time', time, 'success', success, 'initialPlan', initial, ...
        'pathReplaced', replaced, 'oldLength', pathLength(oldPath), ...
        'newLength', pathLength(newPath), ...
        'oldMaximumLateralDeviation', maximumLateralDeviation(oldPath), ...
        'newMaximumLateralDeviation', maximumLateralDeviation(newPath), ...
        'latencySeconds', latency, 'reasons', {reasons}, ...
        'failureReason', newPath.failureReason);
end

function length = pathLength(path)
    length = 0;
    if isstruct(path) && isfield(path, 'length')
        length = path.length;
    end
end

function deviation = maximumLateralDeviation(path)
    deviation = 0;
    if isstruct(path) && isfield(path, 'states') && ~isempty(path.states)
        deviation = max(abs(path.states(:, 2)));
    end
end

function changed = pathsDiffer(oldPath, newPath, cfg)
    if abs(oldPath.length - newPath.length) > cfg.control.pathChangeTolerance
        changed = true;
        return;
    end
    sampleCount = 25;
    oldXY = resamplePath(oldPath.states(:, 1:2), sampleCount);
    newXY = resamplePath(newPath.states(:, 1:2), sampleCount);
    changed = max(hypot(oldXY(:, 1) - newXY(:, 1), ...
        oldXY(:, 2) - newXY(:, 2))) > cfg.control.pathChangeTolerance;
end

function sampled = resamplePath(points, count)
    segment = [0; cumsum(hypot(diff(points(:, 1)), diff(points(:, 2))))];
    if segment(end) <= eps
        sampled = repmat(points(1, :), count, 1);
    else
        [segment, uniqueIndex] = unique(segment, 'stable');
        points = points(uniqueIndex, :);
        query = linspace(0, segment(end), count).';
        sampled = [interp1(segment, points(:, 1), query), ...
            interp1(segment, points(:, 2), query)];
    end
end

function entries = emptyLog()
    entries = repmat(struct('time', 0, 'egoX', 0, 'egoY', 0, ...
        'egoYaw', 0, 'egoSpeed', 0, 'desiredSpeed', 0, 'steering', 0, ...
        'acceleration', 0, 'acargState', '', 'totalRisk', 0, ...
        'safetyScale', 1, 'speedScale', 1, 'replanUrgency', 0, ...
        'replanRequested', false, 'plannerInvoked', false, ...
        'planningSucceeded', false, 'pathReplaced', false, ...
        'pathSafe', false, 'activePathLength', 0, ...
        'minimumActorDistance', inf, 'actorRisks', [], ...
        'actorRiskDetails', struct([]), ...
        'acargDiagnostics', struct(), 'detections', struct([]), ...
        'tracks', struct([]), 'actorTruth', struct([]), ...
        'replanReasons', {{}}, 'pathSafeBeforePlanning', false, ...
        'adaptiveOccupiedCells', 0, 'detectionCount', 0), 0, 1);
end

function entry = makeLogEntry(time, ego, desiredSpeed, steering, acceleration, ...
        acarg, invoked, succeeded, replaced, pathSafe, path, actorDistance, ...
        detections, tracks, actors, replanReasons, pathSafeBefore, adaptiveMap)
    entry = struct('time', time, 'egoX', ego.x, 'egoY', ego.y, ...
        'egoYaw', ego.yaw, 'egoSpeed', ego.speed, ...
        'desiredSpeed', desiredSpeed, 'steering', steering, ...
        'acceleration', acceleration, 'acargState', acarg.state, ...
        'totalRisk', acarg.risk.totalRisk, 'safetyScale', acarg.safetyScale, ...
        'speedScale', acarg.speedScale, 'replanUrgency', acarg.replanUrgency, ...
        'replanRequested', acarg.replanRequested, 'plannerInvoked', invoked, ...
        'planningSucceeded', succeeded, 'pathReplaced', replaced, ...
        'pathSafe', pathSafe, 'activePathLength', pathLength(path), ...
        'minimumActorDistance', actorDistance, ...
        'actorRisks', [acarg.risk.actorRisk.risk], ...
        'actorRiskDetails', acarg.risk.actorRisk, ...
        'acargDiagnostics', acarg.diagnostics, ...
        'detections', detections, 'tracks', tracks, 'actorTruth', actors, ...
        'replanReasons', {replanReasons}, ...
        'pathSafeBeforePlanning', pathSafeBefore, ...
        'adaptiveOccupiedCells', nnz(adaptiveMap.conservativeOccupancyMask), ...
        'detectionCount', sum([detections.IsDetected]));
end
