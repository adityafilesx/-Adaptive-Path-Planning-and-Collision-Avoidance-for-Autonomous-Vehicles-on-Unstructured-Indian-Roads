function capability=validateIDDExecutionEnvironment(cfg)
%VALIDATEIDDEXECUTIONENVIRONMENT Explicit capability fields; no installation.
if nargin<1,cfg=getIDDExecutionConfig();end
r=validateIDDEnvironment(cfg);
capability=struct('YOLOXAvailable',~isempty(which('yoloxObjectDetector')), ...
    'TrainingFunctionAvailable',~isempty(which('trainYOLOXObjectDetector')), ...
    'DeepLearningAvailable',r.deepLearning,'ComputerVisionAvailable',r.computerVision, ...
    'ParallelComputingAvailable',any(string({r.toolboxes.Name})=="Parallel Computing Toolbox"), ...
    'GPUAvailable',r.gpuCount>0,'GPUName',r.gpuName, ...
    'ExecutionEnvironment',string(cfg.executionEnvironment),'details',r);
capability.TrainYOLOXAvailable=capability.TrainingFunctionAvailable;
capability.TrainingOptionsAvailable=~isempty(which('trainingOptions'));
capability.YOLOXAddonAvailable=r.addonInstalled;
capability.Reason="Required YOLOX functions and toolboxes available.";
if ~r.trainingAvailable
    capability.Reason="Missing YOLOX functions or required toolboxes. Required add-on: "+r.addonName+".";
end
if ~capability.GPUAvailable
    capability.Reason=capability.Reason+" No MATLAB-supported GPU available; CPU smoke requires separate feasibility and disk checks.";
end
end
