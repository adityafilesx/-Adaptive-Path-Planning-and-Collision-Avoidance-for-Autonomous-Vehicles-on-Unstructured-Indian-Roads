function collectFinalEvidence()
% Collect completed, independently logged runs; never rerun core algorithms.
audit="results/phase12/phase12_6_audit";
video="results/phase12/videos/all_scenarios/run_20260906_150800_374";
first=readtable(fullfile(audit,"regression_20260906_150927_503","regression_summary.csv"),'TextType','string','Delimiter',',');
last=readtable(fullfile(audit,"regression_20260906_201211_627","regression_summary.csv"),'TextType','string','Delimiter',',');
combined=[first;last];
assert(height(combined)==22&&numel(unique(combined.Task))==22&&all(combined.Status=="PASS"));
writetable(combined,fullfile(audit,'regression_summary.csv'));
m=readtable(fullfile(video,'video_manifest.csv'),'TextType','string','Delimiter',',','VariableNamingRule','preserve');
rows=struct('VideoID',{},'Scenario',{},'Status',{},'FramesDecoded',{},'TitleCardPSNR',{},'FinalCardPSNR',{});
for k=1:height(m)
    loaded=load(m.File(k)+".mat",'validation');p=loaded.validation;
    assert(p.Status=="PASS");
    rows(end+1)=struct('VideoID',m.VideoID(k),'Scenario',m.Scenario(k),'Status',p.Status, ...
        'FramesDecoded',p.FramesDecoded,'TitleCardPSNR',p.TitleCardPSNR,'FinalCardPSNR',p.FinalCardPSNR); %#ok<AGROW>
end
writetable(struct2table(rows),fullfile(audit,'video_validation_summary.csv'));
qa=fullfile(audit,'visual_qa');if ~isfolder(qa),mkdir(qa);end
for k=[2 8 12]
    reader=VideoReader(m.File(k));reader.CurrentTime=reader.Duration-.2;
    pixels=readFrame(reader);
    imwrite(pixels,fullfile(qa,sprintf('%02d_final_card.png',k)));
end
reader=VideoReader(m.File(6));reader.CurrentTime=5.5;
imwrite(readFrame(reader),fullfile(qa,'06_confidence_dip.png'));
fprintf('FINAL COLLECTION: 22 tasks PASS; %d videos; %d frames; %.1f seconds.\n',height(m),sum(m.ExpectedFrames),sum(m.Duration));
disp(struct2table(rows));
end
