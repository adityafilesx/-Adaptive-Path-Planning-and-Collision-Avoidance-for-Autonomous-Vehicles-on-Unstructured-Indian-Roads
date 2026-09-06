function adapter = createPerceptionSource(source)
%CREATEPERCEPTIONSOURCE Integration-only dispatch; core perception stays independent.
if nargin<1,source="SIMULATED";end
if isstruct(source),settings=getIDDConfig(source);source=settings.perceptionMode;end
switch upper(string(source))
    case "SIMULATED",adapter=@simulation;
    case "IDD_IMAGE",adapter=@imageBranch;
    case "ROADRUNNER",adapter=@roadRunner;
    otherwise,error('IDD:Source','Choose SIMULATED, IDD_IMAGE or ROADRUNNER.');
end
end
function packet=simulation(payload,cfg)
packet=simulatedDetectionToCanonical(simulatePerception(payload.actorTruth,payload.egoState,cfg),"SIMULATED",cfg);
end
function packet=imageBranch(payload,cfg)
idd=getIDDConfig(cfg);
packet=iddDetectionToCanonical(runIDDInference(payload.detector,payload.imageFile,idd));
end
function packet=roadRunner(payload,cfg)
% Accept only already calibrated metric detections, never image boxes.
assert(isfield(payload,'metricDetections'),'IDD:RoadRunnerBoundary','Supply calibrated metric detections from the existing RoadRunner bridge. Runtime integration is not added here.');
packet=simulatedDetectionToCanonical(payload.metricDetections,"ROADRUNNER",cfg);
end
