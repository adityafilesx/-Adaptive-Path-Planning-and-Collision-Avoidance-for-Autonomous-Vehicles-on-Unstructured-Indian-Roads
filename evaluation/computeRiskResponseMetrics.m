function metrics = computeRiskResponseMetrics(result)
%COMPUTERISKRESPONSEMETRICS Quantify ACARG response without changing it.

    log=result.log; risks=[log.totalRisk]; speeds=[log.egoSpeed];
    scales=[log.safetyScale]; states=string({log.acargState});
    transitions=sum(states(2:end)~=states(1:end-1));
    dominant=arrayfun(@dominantID,log); valid=isfinite(dominant);
    changes=sum(valid(2:end)&valid(1:end-1)&dominant(2:end)~=dominant(1:end-1));
    actorRisk=0; adaptiveScale=1;
    for i=1:numel(log)
        if ~isempty(log(i).actorRiskDetails)
            actorRisk=max(actorRisk,max([log(i).actorRiskDetails.risk]));
            adaptiveScale=max(adaptiveScale,max([log(i).actorRiskDetails.combinedAdaptiveScale]));
        end
    end
    metrics=struct('MaximumRisk',max(risks),'MeanRisk',mean(risks), ...
        'RiskRange',range(risks),'NumberOfStateTransitions',transitions, ...
        'MinimumSpeedScale',min([log.speedScale]), ...
        'MaximumSafetyScale',max(scales), ...
        'NumberOfReplanRequestedEvents',sum([log.replanRequested]), ...
        'DominantActorChanges',changes,'MaximumActorRisk',actorRisk, ...
        'MaximumAdaptiveEnvelopeScale',adaptiveScale, ...
        'RiskSpeedCorrelation',safeCorrelation(risks,speeds), ...
        'RiskSafetyScaleCorrelation',safeCorrelation(risks,scales), ...
        'RiskReplanCorrelation',safeCorrelation(risks,double([log.replanRequested])));
end
function id=dominantID(frame)
id=NaN;
if isfield(frame.acargDiagnostics,'dominantActorID'),id=frame.acargDiagnostics.dominantActorID;end
end
function value=safeCorrelation(a,b)
if numel(a)<2 || std(a)<eps || std(b)<eps, value=NaN; return; end
c=corrcoef(a,b); value=c(1,2);
end
