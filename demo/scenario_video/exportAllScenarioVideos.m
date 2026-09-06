function result=exportAllScenarioVideos(options)
%EXPORTALLSCENARIOVIDEOS Independent, resumable 5+8 scenario evidence workflow.
if nargin<1,options=struct();end;o=scenarioVideoConfig(options);
if strlength(o.runDirectory)>0
    folder=string(o.runDirectory);assert(isfolder(folder),'Video:RunDirectory','Resume directory does not exist.');
elseif o.reuseComplete
    folders=dir(fullfile(o.outputRoot,'videos','all_scenarios','run_*','video_manifest.csv'));
    if ~isempty(folders)
        [~,order]=sort([folders.datenum],'descend');folder=string(folders(order(1)).folder);
    else,folder="";end
else,folder="";end
if strlength(folder)==0
    checkIDDDiskSpace(o.outputRoot,o.minimumFreeGB,true);
    runID="run_"+string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
    folder=string(fullfile(o.outputRoot,'videos','all_scenarios',runID));mkdir(folder);
end
[~,runID]=fileparts(folder);shotRoot=fullfile(o.outputRoot,'screenshots','all_scenarios',runID);
if ~isfolder(shotRoot),mkdir(shotRoot);end
inventoryFile=fullfile(folder,'replay_inventory.csv');
if strlength(o.replayInventoryFile)>0
    inventory=readtable(o.replayInventoryFile,'TextType','string','Delimiter',',','VariableNamingRule','preserve');writetable(inventory,inventoryFile);
elseif isfile(inventoryFile),inventory=readtable(inventoryFile,'TextType','string','Delimiter',',','VariableNamingRule','preserve');
else,inventory=prepareScenarioVideoReplays(o,folder);end
assert(height(inventory)==13&&numel(unique(inventory.Scenario))==13,'Video:Coverage','Expected 13 distinct authoritative scenarios.');
manifest=table();
for k=1:height(inventory)
    item=inventory(k,:);phaseFolder=fullfile(folder,sprintf('phase%d',item.Phase));
    sidecars=dir(fullfile(phaseFolder,item.FileStem+".*.mat"));
    fprintf('VIDEO %02d/13 START %s\n',k,item.Scenario);
    if ~isempty(sidecars)
        saved=load(fullfile(sidecars(1).folder,sidecars(1).name),'summary');row=saved.summary;
        proof=validateScenarioVideo(row);row.Duration=proof.Duration;row.ExportStatus="VALIDATED";
        summary=row;validation=proof;save(fullfile(sidecars(1).folder,sidecars(1).name),'summary','validation','-v7');
    else
        row=exportOneScenarioVideo(item,o,folder,shotRoot);
    end
    manifest=[manifest;row]; %#ok<AGROW>
    writetable(manifest,fullfile(folder,'video_manifest.csv'));
    fprintf('VIDEO %02d/13 VALIDATED %s | %.1f s | %d frames\n',k,item.Scenario,row.Duration,row.ExpectedFrames);
end
writeScenarioVideoIndex(manifest,folder);
result=struct('status',"SCENARIO VIDEO EVIDENCE COMPLETE",'runDirectory',folder, ...
    'manifestFile',string(fullfile(folder,'video_manifest.csv')),'indexFile',string(fullfile(folder,'VIDEO_INDEX.md')), ...
    'manifest',manifest,'phase8Count',sum(manifest.Phase==8),'phase9Count',sum(manifest.Phase==9), ...
    'validatedCount',sum(manifest.ExportStatus=="VALIDATED"),'screenshotCount',sum(manifest.ScreenshotCount));
assert(result.phase8Count==5&&result.phase9Count==8&&result.validatedCount==13,'Video:Incomplete','Required coverage incomplete.');
save(fullfile(folder,'video_export_summary.mat'),'result','o','-v7');
fprintf('SCENARIO VIDEO EVIDENCE COMPLETE: 5/5 + 8/8 = 13/13 validated; %d screenshots.\n',result.screenshotCount);
end
