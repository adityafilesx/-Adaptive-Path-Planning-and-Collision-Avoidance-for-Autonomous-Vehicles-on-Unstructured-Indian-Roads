function splits = splitIDDData(records)
%SPLITIDDDATA Keep official partition membership. No random train/val leakage.
assert(~isempty(records),'IDD:NoAnnotations','No valid annotated records.');
names=lower(string({records.ImageFile}));
assert(numel(unique(names))==numel(names),'IDD:SplitLeakage','An image occurs in more than one record.');
splits=struct();
for name=["train","val"],splits.(name)=records(string({records.Split})==name);end
assert(~isempty(splits.train)&&~isempty(splits.val),'IDD:EmptySplit','No valid training or validation records.');
end
