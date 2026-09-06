function schemas = getPerceptionSchemas()
%GETPERCEPTIONSCHEMAS Explicit contracts; image semantics do not imply geometry.
image=createImageDetection(zeros(0,4),zeros(0,1),strings(0,1),[1 1 3],"",strings(0,1));
schemas.ImageDetection=struct('fields',{fieldnames(image)},'units',"pixels",'metricReady',false);
schemas.CanonicalActorDetection=struct('fields',{{'ID','Position','Velocity','PerceivedClass','TrueClass', ...
    'Distance','PositionStd','VelocityStd','IsDetected','Confidence'}}, ...
    'units',"metres and metres/second",'metricReady',true);
end
