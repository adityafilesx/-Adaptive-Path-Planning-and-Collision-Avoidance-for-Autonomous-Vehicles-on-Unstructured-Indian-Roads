function [detector,result] = loadIDDDetector(path)
%LOADIDDDETECTOR Reject COCO-only weights being presented as an IDD-trained model.
assert(strlength(string(path))>0&&isfile(path),'IDD:ModelRequired','Configure detectorFile with a genuinely IDD-trained model MAT.');
loaded=load(path,'result');assert(isfield(loaded,'result'),'IDD:ModelProvenance','No IDD training provenance in this model.');
result=loaded.result;
assert(isfield(result,'trainedOnIDD')&&result.trainedOnIDD&&result.provenance.trainingImageCount>0, ...
    'IDD:ModelProvenance','COCO-pretrained initialization alone is not IDD training.');
assert(isa(result.detector,'yoloxObjectDetector'),'IDD:Detector','Saved model is not a MATLAB YOLOX detector.');
detector=result.detector;
end
