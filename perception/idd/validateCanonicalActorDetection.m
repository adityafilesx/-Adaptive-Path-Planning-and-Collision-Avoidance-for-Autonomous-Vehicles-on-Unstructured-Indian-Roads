function valid = validateCanonicalActorDetection(detections)
%VALIDATECANONICALACTORDETECTION Existing metric tracker contract, unchanged.
required={'ID','Position','Velocity','PerceivedClass','TrueClass','Distance', ...
    'PositionStd','VelocityStd','IsDetected','Confidence'};
valid=isstruct(detections)&&all(isfield(detections,required));
if ~valid,return;end
for k=1:numel(detections)
    d=detections(k);
    valid=valid&&isscalar(d.Confidence)&&isfinite(d.Confidence)&&d.Confidence>=0&&d.Confidence<=1;
    valid=valid&&numel(d.Position)==3&&numel(d.Velocity)==3;
    if d.IsDetected,valid=valid&&all(isfinite(d.Position))&&all(isfinite(d.Velocity));end
end
end
