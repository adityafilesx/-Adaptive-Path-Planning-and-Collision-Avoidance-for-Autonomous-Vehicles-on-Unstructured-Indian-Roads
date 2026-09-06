function summary = mainIDDPerceptionDemo(options)
%MAINIDDPERCEPTIONDEMO Genuine validation overlays only; no fallback demo images.
if nargin<1,options=struct();end
addpath(genpath(fileparts(mfilename('fullpath'))));cfg=getIDDConfig(options);
dataset=findIDDDataset(cfg);
summary=struct('status',"NOT RUN - DATASET REQUIRED",'files',strings(0,1));
if ~dataset.available,fprintf('%s\n',dataset.message);return;end
if strlength(string(cfg.detectorFile))==0||~isfile(cfg.detectorFile)
    summary.status="NOT RUN - IDD-TRAINED MODEL REQUIRED";fprintf('%s\n',summary.status);return
end
[detector,model]=loadIDDDetector(cfg.detectorFile);inventory=inspectIDDStructure(cfg);
validation=inventory.files(inventory.files.Split=="val"&inventory.files.ImageExists&inventory.files.AnnotationExists,:);
% Prefer varied class coverage; no scene-type claims inferred from file names.
data=prepareIDDData(cfg);records=data.records(string({data.records.Split})=="val");
selected=[];covered=strings(0,1);remaining=1:numel(records);
for k=1:min(cfg.overlayCount,numel(records))
    gains=arrayfun(@(j) numel(setdiff(records(j).Labels,covered)),remaining);
    [~,best]=max(gains);index=remaining(best);selected(end+1)=index; %#ok<AGROW>
    covered=union(covered,records(index).Labels);remaining(best)=[];
end
stamp=string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));folder=fullfile(cfg.outputDir,'overlays',stamp);mkdir(folder);
files=strings(numel(selected),1);packets=cell(numel(selected),1);sources=files;
for k=1:numel(selected)
    source=records(selected(k)).ImageFile;assert(any(validation.ImageFile==source),'IDD:ValidationOnly','Overlay source is not official validation.');
    detections=runIDDInference(detector,source,cfg);packets{k}=iddDetectionToCanonical(detections);
    files(k)=visualizeIDDDetections(source,detections,fullfile(folder,sprintf('validation_%03d.png',k)));sources(k)=source;
end
writetable(table(sources,files),fullfile(folder,'overlay_manifest.csv'));
summary=struct('status',"PASS",'files',files,'packets',{packets},'sourceImages',sources, ...
    'trainedModelProfile',model.profile,'coverage',covered,'limitation',"Images do not provide metric actor state; scene/illumination coverage needs human review.");
end
