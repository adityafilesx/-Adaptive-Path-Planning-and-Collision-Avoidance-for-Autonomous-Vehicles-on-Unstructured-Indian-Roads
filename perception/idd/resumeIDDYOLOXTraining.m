function result = resumeIDDYOLOXTraining(checkpointFile,cfg)
%RESUMEIDDYOLOXTRAINING Explicit weight continuation with a fresh optimizer.
assert(isfile(checkpointFile),'IDD:CheckpointMissing','Checkpoint file is absent.');
cfg=getIDDConfig(cfg);cfg.resumeFile=string(checkpointFile);
result=trainIDDYOLOX(prepareIDDData(cfg),cfg);
end
