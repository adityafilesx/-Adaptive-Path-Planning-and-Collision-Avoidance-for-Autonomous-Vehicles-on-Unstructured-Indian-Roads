function semantics = getCanonicalPerceptionSemantics(detections,kind,cfg)
%GETCANONICALPERCEPTIONSEMANTICS Shared read-only class/confidence interface.
% Legacy metric records are never rewritten. Numeric simulator classes use
% the existing configured tracker map; image IDs are not simulator class IDs.
if nargin<3,cfg=config();end
n=numel(detections);ids=zeros(n,1);classes=repmat("unknown",n,1);scores=zeros(n,1);detected=false(n,1);
for k=1:n
    d=detections(k);scores(k)=d.Confidence;
    if string(kind)=="IMAGE"
        ids(k)=d.DetectionID;classes(k)=d.Class;detected(k)=true;
    else
        ids(k)=d.ID;detected(k)=d.IsDetected;label=d.PerceivedClass;
        if isnumeric(label)&&isscalar(label)&&isfinite(label)
            key=sprintf('id%d',label);
            if isfield(cfg.tracking.classIDMap,key),classes(k)=string(cfg.tracking.classIDMap.(key));end
        elseif (ischar(label)||isstring(label))&&isscalar(string(label))
            classes(k)=lower(strtrim(string(label))); % preserves simulation-only pushcart
        end
    end
end
semantics=table(ids,classes,scores,detected,'VariableNames',{'DetectionID','Class','Confidence','IsDetected'});
end
