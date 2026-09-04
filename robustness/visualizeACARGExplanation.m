function figures = visualizeACARGExplanation(phase9)
%VISUALIZEACARGEXPLANATION Create compact engineering diagnostic plots.

    runs = phase9.robustness.scenarioRuns;
    index = find(strcmp({runs.scenarioName}, 'Conservative Stop Recovery'), 1);
    log = runs(index).detail.result.log;
    time = [log.time];
    dominantRisk = arrayfun(@(x) x.acargDiagnostics.dominantActorRisk, log);
    actor = arrayfun(@dominantActor, log);
    physicalDistance = arrayfun(@(x) actorValue(x, 'distance'), actor);
    cpaDistance = arrayfun(@(x) collisionValue(x, 'cpaDistance'), actor);
    adaptiveScale = arrayfun(@(x) actorValue(x, 'combinedAdaptiveScale'), actor);
    confidence = arrayfun(@(x) actorValue(x, 'confidence'), actor);
    uncertainty = arrayfun(@(x) actorValue(x, 'uncertainty'), actor);

    figures(1) = figure('Name', 'Phase 9 ACARG Explainability');
    tiledlayout(2, 3);
    nexttile; plot(time, [log.totalRisk], 'LineWidth', 1.4); hold on;
    yline(phase9.denseMarketAudit.stopEntryThreshold, '--r');
    yline(phase9.denseMarketAudit.stopExitThreshold, '--g');
    title('Risk and thresholds'); xlabel('Time (s)'); ylabel('Risk'); grid on;
    nexttile; plot(time, [log.egoSpeed], 'LineWidth', 1.4); hold on;
    plot(time, [log.desiredSpeed], '--', 'LineWidth', 1.2);
    title('Physical speed response'); xlabel('Time (s)'); ylabel('m/s'); grid on;
    legend('ego','desired');
    nexttile; plot(time, dominantRisk, 'LineWidth', 1.4);
    title('Dominant actor risk'); xlabel('Time (s)'); ylabel('Risk'); grid on;
    nexttile; plot(time, physicalDistance, 'LineWidth', 1.4); hold on;
    plot(time, cpaDistance, '--', 'LineWidth', 1.2);
    title('Physical vs CPA distance'); xlabel('Time (s)'); ylabel('m'); grid on;
    legend('physical','CPA');
    nexttile; plot(time, adaptiveScale, 'LineWidth', 1.4);
    title('Adaptive envelope scale'); xlabel('Time (s)'); ylabel('Scale'); grid on;
    nexttile; plot(time, confidence, 'LineWidth', 1.3); hold on;
    plot(time, uncertainty, 'LineWidth', 1.3); plot(time, dominantRisk, 'LineWidth', 1.3);
    title('Trust, uncertainty, risk'); xlabel('Time (s)'); grid on;
    legend('confidence','uncertainty','risk');

    audit = phase9.denseMarketAudit.frameAudit;
    figures(2) = figure('Name', 'Dense Market Legacy STOP Audit');
    plot(audit.Time, audit.UncertaintyContribution, 'LineWidth', 1.3); hold on;
    plot(audit.Time, audit.ConfidenceContribution, 'LineWidth', 1.3);
    plot(audit.Time, audit.DistanceContribution, 'LineWidth', 1.3);
    plot(audit.Time, audit.CollisionContribution, 'LineWidth', 1.3);
    plot(audit.Time, audit.TotalRisk, 'k', 'LineWidth', 1.6);
    yline(phase9.denseMarketAudit.stopEntryThreshold, '--r');
    xlabel('Time (s)'); ylabel('Risk contribution'); grid on;
    title('Dense Market decomposition around legacy STOP');
    legend('uncertainty','inverse confidence','distance','collision','total','STOP entry');
end

function actor = dominantActor(frame)
    actor = struct();
    if isempty(frame.actorRiskDetails), return; end
    id = frame.acargDiagnostics.dominantActorID;
    index = find([frame.actorRiskDetails.ActorID] == id, 1);
    if ~isempty(index), actor = frame.actorRiskDetails(index); end
end

function value = actorValue(actor, field)
    value = NaN;
    if isstruct(actor) && isfield(actor, field), value = actor.(field); end
end

function value = collisionValue(actor, field)
    value = NaN;
    if isstruct(actor) && isfield(actor, 'collisionDiagnostics') && ...
            isfield(actor.collisionDiagnostics, field)
        value = actor.collisionDiagnostics.(field);
    end
end
