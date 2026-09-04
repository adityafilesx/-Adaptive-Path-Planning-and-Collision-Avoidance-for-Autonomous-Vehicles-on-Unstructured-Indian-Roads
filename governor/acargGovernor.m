function acarg = acargGovernor(tracks, egoState, cfg, previousACARG)
%ACARGGOVERNOR Adaptive Confidence-Aware Risk Governor — main orchestrator.
%   For every tracked actor, calculates confidence, uncertainty, class risk,
%   collision risk, and distance risk.  Aggregates into a total risk score,
%   runs the hysteresis state machine, and outputs decisions for adaptive
%   safety envelope, speed scale, and replanning urgency.
%
%   ACARG is a system-level confidence-aware risk governance layer designed
%   for adaptive safety behavior in heterogeneous and uncertain mixed-traffic
%   environments.  It is NOT a novel mathematical algorithm.
%
%   Inputs:
%       tracks        — array of Phase 3 track structs
%       egoState      — struct with Position, Velocity fields
%       cfg           — full project config with cfg.governor.*
%       previousACARG — (optional) previous ACARG output for hysteresis
%
%   Output: acarg struct containing:
%       .risk.totalRisk, .risk.actorRisk, .risk.maxActorRisk
%       .confidence.actorConfidence, .confidence.minConfidence, .confidence.avgConfidence
%       .uncertainty.actorUncertainty, .uncertainty.avgUncertainty
%       .state
%       .safetyScale
%       .speedScale
%       .replanUrgency
%       .replanRequested
%       .diagnostics

    if nargin < 4 || isempty(previousACARG)
        previousState = 'NORMAL';
    else
        previousState = readField(previousACARG, {'state'}, 'NORMAL');
    end

    if ~isfield(cfg, 'governor')
        error('acargGovernor:MissingConfig', 'cfg.governor is required.');
    end

    % ---- handle empty actor list ----
    if isempty(tracks)
        acarg = emptyACARG(previousState, cfg);
        return;
    end

    % ---- per-actor risk evaluation ----
    n = numel(tracks);
    actorRisks = [];
    actorConfidences  = zeros(1, n);
    actorUncertainties = zeros(1, n);
    egoPath = [];   % no committed path — Phase 5 plans fresh

    for i = 1:n
        track = tracks(i);
        prediction = predictionForTrack(track, cfg);
        ar = computeActorRisk(track, prediction, egoState, egoPath, cfg);
        if i == 1
            actorRisks = ar;
        else
            actorRisks(i) = ar; %#ok<AGROW>
        end
        actorConfidences(i)  = ar.confidence;
        actorUncertainties(i) = ar.uncertainty;
    end

    % ---- aggregate total risk: 1 - prod(1 - R_i) ----
    riskValues = [actorRisks.risk];
    totalRisk = 1 - prod(1 - riskValues);
    totalRisk = min(1, max(0, totalRisk));
    maxActorRisk = max(riskValues);
    minConfidence = min(actorConfidences);
    avgConfidence = mean(actorConfidences);
    avgUncertainty = mean(actorUncertainties);

    % ---- governor state machine with hysteresis ----
    governorState = governorStateMachine(totalRisk, previousState, cfg);

    % ---- global safety scale from final governor state ----
    safetyScale = safetyScaleForState(governorState, cfg);

    % ---- speed scale from final governor state ----
    speedScale = speedScaleForState(governorState, cfg);

    for i = 1:numel(actorRisks)
        actorRisks(i).stateSafetyScale = safetyScale;
        actorRisks(i).combinedAdaptiveScale = ...
            actorRisks(i).safetyScale * safetyScale;
        actorRisks(i).effectiveSafetyExtentX = ...
            actorRisks(i).baseSafetyExtentX * actorRisks(i).combinedAdaptiveScale;
        actorRisks(i).effectiveSafetyExtentY = ...
            actorRisks(i).baseSafetyExtentY * actorRisks(i).combinedAdaptiveScale;
    end

    % ---- replanning urgency ----
    replanCfg = governorSubField(cfg, 'replan', struct());
    riskWeight = fieldOr(replanCfg, 'riskUrgencyWeight', 0.6);
    confWeight = fieldOr(replanCfg, 'confidenceUrgencyWeight', 0.4);
    replanUrgency = riskWeight * totalRisk + confWeight * (1 - minConfidence);
    replanUrgency = min(1, max(0, replanUrgency));
    urgencyThreshold = fieldOr(replanCfg, 'urgencyThreshold', 0.5);
    replanRequested = replanUrgency > urgencyThreshold || ...
        strcmp(governorState, 'CONSERVATIVE_STOP');

    % ---- package output ----
    acarg = struct();
    acarg.risk.totalRisk    = totalRisk;
    acarg.risk.maxActorRisk = maxActorRisk;
    acarg.risk.actorRisk    = actorRisks;

    acarg.confidence.actorConfidence = actorConfidences;
    acarg.confidence.minConfidence   = minConfidence;
    acarg.confidence.avgConfidence   = avgConfidence;

    acarg.uncertainty.actorUncertainty = actorUncertainties;
    acarg.uncertainty.avgUncertainty   = avgUncertainty;

    acarg.state          = governorState;
    acarg.safetyScale    = safetyScale;
    acarg.speedScale     = speedScale;
    acarg.replanUrgency  = replanUrgency;
    acarg.replanRequested = replanRequested;

    acarg.diagnostics.previousState  = previousState;
    acarg.diagnostics.stateChanged   = ~strcmp(governorState, previousState);
    acarg.diagnostics.actorCount     = n;
    acarg.diagnostics.riskValues     = riskValues;
    [~, dominantIndex] = max(riskValues);
    acarg.diagnostics.dominantActorIndex = dominantIndex;
    acarg.diagnostics.dominantActorID = actorRisks(dominantIndex).ActorID;
    acarg.diagnostics.dominantActorRisk = actorRisks(dominantIndex).risk;
    acarg.diagnostics.dominantActorClass = actorRisks(dominantIndex).perceivedClass;
    acarg.diagnostics.thresholds = cfg.governor.thresholds;
    stateExplanation = explainStateDecision( ...
        totalRisk, previousState, governorState, cfg.governor.thresholds);
    acarg.diagnostics.relevantThresholdName = stateExplanation.thresholdName;
    acarg.diagnostics.relevantThreshold = stateExplanation.threshold;
    acarg.diagnostics.thresholdCrossed = stateExplanation.thresholdCrossed;
    acarg.diagnostics.hysteresisActive = stateExplanation.hysteresisActive;
    acarg.diagnostics.stateReason = stateExplanation.reason;
end

%% ---- empty scene ----

function acarg = emptyACARG(previousState, cfg)
    governorState = governorStateMachine(0, previousState, cfg);
    acarg = struct();
    acarg.risk.totalRisk    = 0;
    acarg.risk.maxActorRisk = 0;
    acarg.risk.actorRisk    = [];

    acarg.confidence.actorConfidence = [];
    acarg.confidence.minConfidence   = 1;
    acarg.confidence.avgConfidence   = 1;

    acarg.uncertainty.actorUncertainty = [];
    acarg.uncertainty.avgUncertainty   = 0;

    acarg.state          = governorState;
    acarg.safetyScale    = safetyScaleForState(governorState, cfg);
    acarg.speedScale     = speedScaleForState(governorState, cfg);
    acarg.replanUrgency  = 0;
    acarg.replanRequested = false;

    acarg.diagnostics.previousState  = previousState;
    acarg.diagnostics.stateChanged   = ~strcmp(governorState, previousState);
    acarg.diagnostics.actorCount     = 0;
    acarg.diagnostics.riskValues     = [];
    acarg.diagnostics.dominantActorIndex = NaN;
    acarg.diagnostics.dominantActorID = NaN;
    acarg.diagnostics.dominantActorRisk = 0;
    acarg.diagnostics.dominantActorClass = '';
    acarg.diagnostics.thresholds = cfg.governor.thresholds;
    stateExplanation = explainStateDecision( ...
        0, previousState, governorState, cfg.governor.thresholds);
    acarg.diagnostics.relevantThresholdName = stateExplanation.thresholdName;
    acarg.diagnostics.relevantThreshold = stateExplanation.threshold;
    acarg.diagnostics.thresholdCrossed = stateExplanation.thresholdCrossed;
    acarg.diagnostics.hysteresisActive = stateExplanation.hysteresisActive;
    acarg.diagnostics.stateReason = stateExplanation.reason;
end

function explanation = explainStateDecision(risk, previousState, finalState, thresholds)
    previousState = upper(char(previousState));
    finalState = upper(char(finalState));
    thresholdName = '';
    threshold = NaN;
    crossed = ~strcmp(previousState, finalState);
    hysteresisActive = false;
    if strcmp(previousState, 'NORMAL')
        thresholdName = 'cautiousEnter';
        threshold = thresholds.cautiousEnter;
        if strcmp(finalState, 'CONSERVATIVE_STOP')
            thresholdName = 'conservativeEnter';
            threshold = thresholds.conservativeEnter;
        end
    elseif strcmp(previousState, 'CAUTIOUS')
        if strcmp(finalState, 'CONSERVATIVE_STOP')
            thresholdName = 'conservativeEnter';
            threshold = thresholds.conservativeEnter;
        elseif strcmp(finalState, 'NORMAL')
            thresholdName = 'cautiousExit';
            threshold = thresholds.cautiousExit;
        else
            thresholdName = 'cautiousExit/conservativeEnter';
            threshold = [thresholds.cautiousExit thresholds.conservativeEnter];
            hysteresisActive = risk < thresholds.cautiousEnter;
        end
    elseif strcmp(previousState, 'CONSERVATIVE_STOP')
        if strcmp(finalState, 'CONSERVATIVE_STOP')
            thresholdName = 'conservativeExit';
            threshold = thresholds.conservativeExit;
            hysteresisActive = risk < thresholds.conservativeEnter;
        elseif strcmp(finalState, 'NORMAL')
            thresholdName = 'cautiousExit';
            threshold = thresholds.cautiousExit;
        else
            thresholdName = 'conservativeExit';
            threshold = thresholds.conservativeExit;
        end
    end
    if crossed
        reason = sprintf('%s -> %s at totalRisk %.6f against %s.', ...
            previousState, finalState, risk, thresholdName);
    elseif hysteresisActive
        reason = sprintf('%s retained by hysteresis at totalRisk %.6f.', ...
            finalState, risk);
    else
        reason = sprintf('%s retained at totalRisk %.6f.', finalState, risk);
    end
    explanation = struct('thresholdName', thresholdName, ...
        'threshold', threshold, 'thresholdCrossed', crossed, ...
        'hysteresisActive', hysteresisActive, 'reason', reason);
end

%% ---- prediction helper (reuses Phase 4 pattern) ----

function prediction = predictionForTrack(track, cfg)
    processNoise = readField(track, {'ProcessNoise'}, ...
        cfg.tracking.defaultProcessNoise);
    covariance = readField(track, {'CurrentCovariance'}, []);
    if ~isequal(size(covariance), [4 4]) || any(~isfinite(covariance(:)))
        covariance = cfg.occupancy.invalidCovarianceVariance * eye(4);
    end
    prediction = predictActor(track.CurrentState, covariance, ...
        cfg.prediction.horizon, cfg.prediction.dt, ...
        struct('ProcessNoise', processNoise));
end

%% ---- local helpers ----

function value = governorSubField(cfg, sub, fallback)
    if nargin < 3
        fallback = struct();
    end
    if isfield(cfg, 'governor') && isfield(cfg.governor, sub)
        value = cfg.governor.(sub);
    else
        value = fallback;
    end
end

function speedScale = speedScaleForState(governorState, cfg)
    speedScales = governorSubField(cfg, 'speedScale', struct());
    switch governorState
        case 'NORMAL'
            fieldName = 'NORMAL';
        case 'CAUTIOUS'
            fieldName = 'CAUTIOUS';
        case 'CONSERVATIVE_STOP'
            fieldName = 'CONSERVATIVE_STOP';
        otherwise
            error('acargGovernor:UnknownState', ...
                'Cannot map speed scale for governor state "%s".', governorState);
    end

    if ~isfield(speedScales, fieldName)
        error('acargGovernor:MissingSpeedScale', ...
            'cfg.governor.speedScale.%s is required.', fieldName);
    end
    speedScale = min(1, max(0, speedScales.(fieldName)));
end

function safetyScale = safetyScaleForState(governorState, cfg)
    envelopeConfig = governorSubField(cfg, 'safetyEnvelope', struct());
    if ~isfield(envelopeConfig, 'stateScale') || ...
            ~isfield(envelopeConfig.stateScale, governorState)
        error('acargGovernor:MissingSafetyScale', ...
            'cfg.governor.safetyEnvelope.stateScale.%s is required.', ...
            governorState);
    end
    safetyScale = envelopeConfig.stateScale.(governorState);
end

function value = fieldOr(s, name, fallback)
    if isstruct(s) && isfield(s, name)
        value = s.(name);
    else
        value = fallback;
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
