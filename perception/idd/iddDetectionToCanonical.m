function packet = iddDetectionToCanonical(detections)
%IDDDETECTIONTOCANONICAL Shared semantic interface; explicitly not metric-ready.
assert(isstruct(detections),'IDD:Schema','Expected ImageDetection records.');
assert(~isfield(detections,'Position')&&~isfield(detections,'Velocity'),'IDD:MetricLeak','Image detections must not contain metric state.');
schemas=getPerceptionSchemas();
assert(all(isfield(detections,schemas.ImageDetection.fields)),'IDD:Schema','Missing ImageDetection fields.');
if ~isempty(detections)
    assert(all(string({detections.Schema})=="ImageDetection"),'IDD:Schema','Expected ImageDetection schema.');
    for k=1:numel(detections)
        d=detections(k);[clipped,ok]=validateIDDBoxes(d.BBox,d.ImageSize);
        assert(isequal(size(d.BBox),[1 4])&&all(ok)&&isequal(clipped,d.BBox)&&isscalar(d.Confidence)&&isfinite(d.Confidence)&&d.Confidence>=0&&d.Confidence<=1,'IDD:Schema','Invalid image detection.');
        assert(d.Class==mapIDDClass(d.OriginalIDDClass),'IDD:Mapping','Canonical label disagrees with mapping.');
    end
end
packet=struct('Schema',"CanonicalPerceptionPacket",'Source',"IDD_IMAGE", ...
    'CoordinateSpace',"IMAGE_PIXELS",'MetricReady',false,'Detections',detections, ...
    'RequiredNextStage',"DEPTH / CALIBRATION / SENSOR FUSION");
packet.Semantics=getCanonicalPerceptionSemantics(detections,"IMAGE");
end
