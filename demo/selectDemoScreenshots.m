function shots = selectDemoScreenshots(data)
%SELECTDEMOSCREENSHOTS Select real events, never synthesize dramatic states.
l=data.result.log;r=[l.totalRisk];states=string({l.acargState});
low=find(states=="NORMAL",1);if isempty(low),low=1;end
rising=find(diff(r)>.01,1)+1;if isempty(rising),rising=low;end
caution=find(states=="CAUTIOUS",1);if isempty(caution),caution=low;end
scale=arrayfun(@(f) max([1 f.actorRiskDetails.combinedAdaptiveScale]),l);
[~,enlarged]=max(scale);
changed=find([l.pathReplaced]&[l.time]>0,1);if isempty(changed),changed=1;end
% Prefer the strongest recorded lateral detour, not merely a periodic refresh.
candidates=find([l.pathReplaced]&[l.time]>0);
if ~isempty(candidates)
    spans=arrayfun(@(k) range(data.result.presentationFrames(k).pathStates(:,2)),candidates);
    [~,best]=max(spans);changed=candidates(best);
end
recovery=find(states=="NORMAL"&(1:numel(l))>caution,1);
if isempty(recovery),recovery=numel(l);end
frames=[low rising caution enlarged changed recovery numel(l)].';
names=["A_low_risk";"B_rising_risk";"C_cautious";"D_largest_envelope";"E_replanned";"F_recovery";"G_final_outcome"];
shots=table(names,frames,[l(frames).time].',states(frames).',r(frames).', ...
    'VariableNames',{'Name','Frame','Time','State','Risk'});
end
