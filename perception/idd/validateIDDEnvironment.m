function report = validateIDDEnvironment(cfg)
%VALIDATEIDDENvironment Capability inventory only; never initializes/downloads weights.
if nargin<1,cfg=getIDDConfig();end
names=["yoloxObjectDetector","trainYOLOXObjectDetector","trainingOptions", ...
    "imageDatastore","boxLabelDatastore","objectDetectorTrainingData","evaluateObjectDetection"];
locations=arrayfun(@(x) string(which(char(x))),names);
report=struct('matlabVersion',string(version),'computer',string(computer), ...
    'toolboxes',ver,'functions',table(names.',locations.',strlength(locations.')>0, ...
    'VariableNames',{'Function','Location','Available'}));
products=string({report.toolboxes.Name});
report.deepLearning=any(products=="Deep Learning Toolbox");report.computerVision=any(products=="Computer Vision Toolbox");
report.addonName="Automated Visual Inspection Library for Computer Vision Toolbox";
report.addonInstalled=false;
try
    report.addons=matlab.addons.installedAddons();
    report.addonInstalled=any(contains(string(report.addons.Name),report.addonName)&report.addons.Enabled);
catch info,report.addons=table();report.addonInventoryMessage=string(info.message);end
report.yoloxAvailable=all(strlength(locations(1:2))>0);
report.trainingAvailable=report.deepLearning&&report.computerVision&&all(strlength(locations(1:5))>0);
report.gpuCount=0;report.gpuName="NONE";
if ~isempty(which('gpuDeviceCount'))
    try,report.gpuCount=gpuDeviceCount('available');if report.gpuCount>0,g=gpuDevice;report.gpuName=string(g.Name);end
    catch info,report.gpuMessage=string(info.message);end
end
report.disk=checkIDDDiskSpace(cfg.outputDir,cfg.minimumTrainingFreeGB);
report.status="PASS";
if ~report.trainingAvailable,report.status="CAPABILITY FAILURE: YOLOX functions/add-on or required toolboxes unavailable";end
end
