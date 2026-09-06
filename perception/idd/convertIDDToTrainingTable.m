function trainingTable = convertIDDToTrainingTable(records,classes)
%CONVERTIDDTOTRAININGTABLE References image files; never copies pixel data.
classes=string(classes(:));assert(~isempty(classes)&&numel(unique(classes))==numel(classes),'IDD:Classes','Specify unique observed training classes.');
assert(~any(classes=="imageFilename"),'IDD:Classes','Reserved table column collides with an annotation class.');
trainingTable=table(string({records.ImageFile}).','VariableNames',{'imageFilename'});
for k=1:numel(classes)
    boxes=cell(numel(records),1);
    for i=1:numel(records),boxes{i}=records(i).Boxes(records(i).Labels==classes(k),:);end
    trainingTable.(char(classes(k)))=boxes;
end
end
