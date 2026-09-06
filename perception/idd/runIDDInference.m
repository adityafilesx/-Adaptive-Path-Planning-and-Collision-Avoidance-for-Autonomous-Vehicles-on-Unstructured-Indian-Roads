function detections = runIDDInference(detector,imageFile,cfg)
%RUNIDDINFERENCE Convert actual YOLOX outputs without inventing world geometry.
assert(isa(detector,'yoloxObjectDetector'),'IDD:Detector','Expected MATLAB YOLOX detector.');
assert(isfile(imageFile),'IDD:ImageRequired','Genuine image file is required.');
image=imread(imageFile);if size(image,3)==1,image=repmat(image,1,1,3);end
[boxes,scores,labels]=detect(detector,image,'Threshold',cfg.scoreThreshold, ...
    'ExecutionEnvironment',char(cfg.executionEnvironment));
detections=createImageDetection(boxes,scores,labels,size(image),string(imageFile),string(detector.ClassNames));
end
