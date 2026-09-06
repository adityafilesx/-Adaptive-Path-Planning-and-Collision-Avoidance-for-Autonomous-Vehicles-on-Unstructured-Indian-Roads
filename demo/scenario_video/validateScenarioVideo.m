function proof=validateScenarioVideo(row)
%VALIDATESCENARIOVIDEO Decode every frame and compare manifest with saved truth.
assert(isfile(row.File)&&isfile(row.SourceLog),'Video:Missing','Video/replay absent.');
assert(ismember('RendererVersion',row.Properties.VariableNames)&&row.RendererVersion==2,'Video:RendererVersion','Superseded renderer; regenerate from saved replay.');
file=dir(row.File);assert(file.bytes>0,'Video:Empty','Empty video.');
s=load(row.SourceLog,'data');d=s.data;r=d.result;
assert(d.replayVerified&&d.benchmarkVersion=="POST_PHASE9_FIX",'Video:StaleSource','Unverified replay.');
assert(row.Scenario==string(d.scenario.name)&&row.Outcome==d.outcome&& ...
    row.GoalReached==r.goalReached&&row.Collision==r.collisionOccurred&&row.SafeTermination==d.safeTermination, ...
    'Video:Outcome','Manifest differs from authoritative source.');
assert(abs(row.PeakRisk-max([r.log.totalRisk]))<1e-12&&row.Replans==r.numberOfReplans,'Video:Metrics','Incorrect displayed metrics.');
assert(all(isfile([row.InitialScreenshot,row.KeyScreenshot,row.FinalScreenshot])),'Video:Screenshots','Required screenshots absent.');
timeline=readtable(row.File+".timeline.csv",'TextType','string','Delimiter',',','VariableNamingRule','preserve');
assert(height(timeline)==row.ExpectedFrames&&all(diff(timeline.VideoTime)>0),'Video:Timeline','Invalid encoded timing schedule.');
body=timeline(timeline.Kind=="REPLAY",:);times=[r.log.time];
assert(isequal(unique(body.LogFrame).',(1:numel(times)))&&max(abs(body.SimulationTime-times(body.LogFrame).'))<1e-9, ...
    'Video:Timeline','Replay omits frames or changes simulation times.');
first=find(timeline.Kind=="REPLAY",1);assert(abs(timeline.VideoTime(first)-row.TitleSeconds)<1e-9,'Video:Timing','Wrong title offset.');
reader=VideoReader(row.File);assert(reader.Duration>0&&reader.FrameRate==row.FrameRate,'Video:Metadata','Invalid video timing.');
assert(reader.Width==row.Width&&reader.Height==row.Height,'Video:Resolution','Unexpected frame resolution.');
count=0;firstPixels=[];
while hasFrame(reader)
    frame=readFrame(reader);assert(~isempty(frame),'Video:Decode','Undecodable frame.');count=count+1;
    if count==1,firstPixels=frame;end
end
assert(count==row.ExpectedFrames&&abs(reader.Duration-count/row.FrameRate)<1/row.FrameRate, ...
    'Video:Frames','Truncated video or changed duration.');
% Verify encoded scenario/outcome cards, not merely matching file names.
o=scenarioVideoConfig();expectedTitle=renderScenarioVideoCard(d,row.Phase,"TITLE",o);
expectedFinal=renderScenarioVideoCard(d,row.Phase,"FINAL",o);
titlePSNR=cardPSNR(firstPixels,expectedTitle);finalPSNR=cardPSNR(frame,expectedFinal);
assert(titlePSNR>34&&finalPSNR>34,'Video:CardIdentity','Encoded title/final card differs from authoritative scenario/outcome.');
proof=struct('Status',"PASS",'FramesDecoded',count,'Duration',reader.Duration, ...
    'Width',reader.Width,'Height',reader.Height,'Bytes',file.bytes,'Scenario',row.Scenario, ...
    'Outcome',row.Outcome,'SourceVerified',true,'TitleCardPSNR',titlePSNR,'FinalCardPSNR',finalPSNR);
end
function value=cardPSNR(actual,expected)
% Text-bearing central area; tolerate H.264 loss, reject swapped scenarios.
rows=140:660;cols=60:1370;
delta=double(actual(rows,cols,:))-double(expected(rows,cols,:));
mse=mean(delta(:).^2);value=10*log10(255^2/max(mse,eps));
end
