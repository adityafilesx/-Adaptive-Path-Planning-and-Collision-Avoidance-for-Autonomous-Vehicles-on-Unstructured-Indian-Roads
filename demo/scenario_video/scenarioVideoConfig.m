function o=scenarioVideoConfig(overrides)
%SCENARIOVIDEOCONFIG Presentation/storage only; no autonomy parameters.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
o=struct('outputRoot',string(fullfile(root,'results','phase12')), ...
    'sourceFile',"",'runDirectory',"",'replayInventoryFile',"",'rendererVersion',2,'frameRate',10,'playbackSpeed',1, ...
    'titleSeconds',1.5,'finalSeconds',3,'resolution',[1440 900], ...
    'quality',85,'minimumFreeGB',2,'minimumDuringExportGB',.5,'reuseComplete',true);
if nargin<1,overrides=struct();end
names=fieldnames(overrides);
for k=1:numel(names)
    assert(isfield(o,names{k}),'Video:Config','Unknown video option %s.',names{k});
    o.(names{k})=overrides.(names{k});
end
assert(o.frameRate==10&&o.playbackSpeed==1,'Video:Timing','This standardized set uses 10 fps and truthful 1x replay.');
assert(isequal(o.resolution,[1440 900]),'Video:Resolution','Use the standardized 1440 x 900 frame.');
assert(o.titleSeconds>=1&&o.finalSeconds>=2,'Video:Cards','Cards need readable hold durations.');
end
