function detector = createIDDYOLOXDetector(classes,cfg)
%CREATEIDDYOLOXDETECTOR Transfer learning only; no silent framework/weight download.
cap=validateIDDEnvironment(cfg);
assert(cap.trainingAvailable,'IDD:YOLOXUnavailable','%s. Install the Automated Visual Inspection Library add-on.',cap.status);
assert(~isempty(classes),'IDD:Classes','Actual training annotations must determine model classes first.');
checkIDDDiskSpace(cfg.outputDir,cfg.minimumTrainingFreeGB,true);
if strlength(string(cfg.pretrainedDetectorFile))>0
    loaded=load(cfg.pretrainedDetectorFile,'detector');
    assert(isfield(loaded,'detector')&&isa(loaded.detector,'yoloxObjectDetector'),'IDD:Pretrained','Expected a YOLOX detector MAT variable named detector.');
    assert(isequal(string(loaded.detector.ClassNames(:)),string(classes(:))),'IDD:PretrainedClasses', ...
        'Local initialization must already be configured for these observed IDD classes.');
    detector=loaded.detector;
else
    assert(cfg.allowWeightDownload,'IDD:WeightsRequired', ...
        'Pretrained weights may require a download. Supply pretrainedDetectorFile or explicitly enable allowWeightDownload. No IDD data are downloaded.');
    detector=yoloxObjectDetector(cfg.pretrainedName,cellstr(classes),InputSize=cfg.inputSize);
end
end
