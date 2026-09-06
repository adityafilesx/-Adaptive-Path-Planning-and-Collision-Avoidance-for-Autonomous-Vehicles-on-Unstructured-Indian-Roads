function packet = simulatedDetectionToCanonical(detections,source,cfg)
%SIMULATEDDETECTIONTOCANONICAL Preserve all existing fields and missing detections.
if nargin<2,source="SIMULATED";end
if nargin<3,cfg=config();end
assert(validateCanonicalActorDetection(detections),'IDD:MetricSchema','Expected the existing CanonicalActorDetection metric contract.');
packet=struct('Schema',"CanonicalPerceptionPacket",'Source',string(source), ...
    'CoordinateSpace',"WORLD_METRES",'MetricReady',true,'Detections',detections, ...
    'RequiredNextStage',"EXISTING METRIC TRACKER");
packet.Semantics=getCanonicalPerceptionSemantics(detections,"METRIC",cfg);
end
