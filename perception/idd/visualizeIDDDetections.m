function path = visualizeIDDDetections(imageFile,detections,path)
%VISUALIZEIDDDETECTIONS Actual image overlays, original label -> canonical class.
image=imread(imageFile);labels=strings(numel(detections),1);
for k=1:numel(detections)
    d=detections(k);labels(k)=sprintf('%s -> %s | %.2f',d.OriginalIDDClass,d.Class,d.Confidence);
end
if ~isempty(detections),image=insertObjectAnnotation(image,'rectangle',vertcat(detections.BBox),cellstr(labels));end
imwrite(image,path);
end
