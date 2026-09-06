function audit = runIDDRegressionAudit(requested,auditRoot)
%RUNIDDREGRESSIONAUDIT Test orchestration outside core perception modules.
cfg=getIDDConfig();if nargin>1,cfg.outputDir=string(auditRoot);end
if ~isfolder(cfg.outputDir),mkdir(cfg.outputDir);end
stamp=char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
folder=fullfile(cfg.outputDir,['regression_' stamp]);mkdir(folder);
names=["testPerception","testTracking","testOccupancy","testPlanning", ...
    "testACARG","testClosedLoop","testPhase8Scenarios","testPhase9Robustness", ...
    "testRoadRunnerIntegration","testPhase11Evaluation","testPhase12Demo", ...
    "testIDDIntegration","mainPhase6","mainPhase7","mainPhase8","mainPhase9", ...
    "mainPhase10","mainPhase11","mainPhase12","mainPhase12_5", ...
    "testScenarioVideoExport","mainPhase12_6"];
if nargin>0
    requested=string(requested(:)).';
    assert(all(ismember(requested,names)),'IDD:AuditTask','Unknown regression task.');
    names=requested;
end
before=get(groot,'DefaultFigureVisible');cleanup=onCleanup(@() set(groot,'DefaultFigureVisible',before)); %#ok<NASGU>
set(groot,'DefaultFigureVisible','off');
rows=struct('Task',{},'Status',{},'Seconds',{},'FreeGBBefore',{},'Detail',{},'Log',{});
for k=1:numel(names)
    name=names(k);required=.30;
    if any(name==["testPhase11Evaluation","mainPhase11"]),required=.85;end
    space=checkIDDDiskSpace(cfg.outputDir,required);timer=tic;detail="";output="";
    fprintf('REGRESSION START %s (%.2f GiB available)\n',name,space.availableGB);
    if ~space.sufficient
        status="BLOCKED_DISK";detail=sprintf('Requires %.2f GiB free (evidence plus reserve); no prior evidence deleted.',required);
    else
        try
            [output,failure]=execute(name);status="PASS";
            if ~isempty(failure),status="FAIL";detail=string(getReport(failure,'extended','hyperlinks','off'));end
            assert(isempty(regexp(output,'[1-9][0-9]* failed|TEST [0-9]+ FAILED','once')), ...
                'IDD:RegressionFailed','Suite output reports failed checks.');
        catch info,status="FAIL";detail=string(getReport(info,'extended','hyperlinks','off'));end
    end
    path=string(fullfile(folder,char(name+".txt")));writeLog(path,string(output)+newline+detail);
    rows(end+1)=struct('Task',name,'Status',status,'Seconds',toc(timer), ...
        'FreeGBBefore',space.availableGB,'Detail',detail,'Log',path); %#ok<AGROW>
    audit=struct2table(rows);writetable(audit,fullfile(folder,'regression_summary.csv'));
    fprintf('REGRESSION END %s: %s (%.1f s)\n',name,status,rows(end).Seconds);
    close all force;
end
fprintf('Regression audit: %s\n',folder);disp(audit(:,1:3));
end
function [output,failure]=execute(name)
% Each script gets a separate workspace; no edits or parameter changes to tests.
failure=[];
if name=="mainPhase12"
    command='mainPhase12(struct(''visible'',''off'',''animate'',false,''holdFinalFrame'',false));';
else,command=char(name);end
% Catch inside evalc so assertion failures do not discard earlier test output.
output=evalc('try; invoke(command); catch caught; failure=caught; fprintf(''%s\n'',getReport(caught,''extended'',''hyperlinks'',''off'')); end');
end
function invoke(command)
% Legacy entry scripts use CLEAR; contain it in this disposable workspace.
eval(command);
end
function writeLog(path,output)
fid=fopen(path,'w');assert(fid>=0,'IDD:LogWrite','Cannot create audit log.');guard=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',output);
end
