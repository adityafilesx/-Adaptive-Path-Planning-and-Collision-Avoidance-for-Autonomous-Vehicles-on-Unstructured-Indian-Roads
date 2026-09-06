function detections = createImageDetection(boxes,scores,labels,imageSize,frameName,classNames,timestamp,source)
%CREATEIMAGEDETECTION Explicit image-space schema. Never Position or Velocity.
if nargin<7,timestamp=NaN;end
if nargin<8,source="IDD";end
labels=string(labels(:));scores=double(scores(:));classNames=string(classNames(:));
assert(numel(unique(classNames))==numel(classNames)&&all(strlength(labels)>0),'IDD:Class','Detector class vocabulary must be unique and output labels nonempty.');
[boxes,valid]=validateIDDBoxes(boxes,imageSize);
assert(all(valid)&&numel(scores)==size(boxes,1)&&numel(labels)==numel(scores),'IDD:Detection','Malformed detector output.');
assert(all(isfinite(scores)&scores>=0&scores<=1),'IDD:Confidence','Confidence must be finite in [0,1].');
assert(all(ismember(labels,classNames)),'IDD:Class','Output label missing from actual detector ClassNames.');
t=struct('Schema',"ImageDetection",'DetectionID',0,'Class',"unknown", ...
    'OriginalIDDClass',"",'ClassID',0,'Confidence',0,'BBox',zeros(1,4), ...
    'BBoxCenter',zeros(1,2),'ImageSize',imageSize,'FrameName',string(frameName), ...
    'Timestamp',timestamp,'Source',string(source));
detections=repmat(t,numel(scores),1);
for k=1:numel(scores)
    detections(k).DetectionID=k;detections(k).OriginalIDDClass=labels(k);
    detections(k).Class=mapIDDClass(labels(k));detections(k).ClassID=find(classNames==labels(k),1);
    detections(k).Confidence=scores(k);detections(k).BBox=boxes(k,:);
    detections(k).BBoxCenter=boxes(k,1:2)+(boxes(k,3:4)-1)/2;
end
end
