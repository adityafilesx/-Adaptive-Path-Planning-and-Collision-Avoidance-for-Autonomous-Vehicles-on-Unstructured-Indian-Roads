function proof=validateIDDMilestoneData(data,cfg)
%VALIDATEIDDMILESTONEDATA Real source-backed checks before any smoke training.
% This branch requires genuine files; no synthetic images/XML are constructed.
checkIDDDiskSpace(cfg.outputDir,cfg.minimumConversionFreeGB,true);
assert(isempty(intersect(data.train.imageFilename,data.val.imageFilename)),'IDD:SplitLeakage','Train/val overlap.');
records=data.records;assert(numel(records)>=20&&height(data.val)>=20, ...
    'IDD:AuditCoverage','Need at least 20 accepted real samples and 20 held-out validation images.');
for k=1:numel(records)
    r=records(k);[boxes,ok]=validateIDDBoxes(r.Boxes,r.ImageSize);
    assert(isfile(r.ImageFile)&&isfile(r.AnnotationFile)&&all(ok)&&isequal(boxes,r.Boxes)&& ...
        size(boxes,1)==numel(r.Labels)&&all(strlength(r.Labels)>0),'IDD:Annotations','Invalid accepted record.');
end
stamp=string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
annotationDir=fullfile(cfg.outputDir,'annotation_checks',stamp);
augmentationDir=fullfile(cfg.outputDir,'augmentation_checks',stamp);
mkdir(annotationDir);mkdir(augmentationDir);
previous=rng;guard=onCleanup(@() rng(previous));rng(cfg.randomSeed,'twister');
indices=randperm(numel(records),20);annotationFiles=strings(20,1);
for k=1:20
    r=records(indices(k));pixels=imread(r.ImageFile);
    if ~isempty(r.Boxes),pixels=insertObjectAnnotation(pixels,'rectangle',r.Boxes,cellstr(r.Labels));end
    pixels=insertText(pixels,[5 5],'GENUINE IDD GROUND TRUTH - parsed / safely clipped');
    imwrite(pixels,fullfile(annotationDir,sprintf('%03d.png',k)));annotationFiles(k)=r.ImageFile;
end
writetable(table((1:20).',annotationFiles,'VariableNames',{'OverlayID','SourceImage'}),fullfile(annotationDir,'source_manifest.csv'));
combined=[data.train;data.val];selected=randperm(height(combined),20);
sampleFiles=combined.imageFilename(selected);augmentedFiles=strings(10,1);
for k=1:20
    entry=combined(selected(k),:);ds=buildIDDDetectionDatastore(entry);sample=read(ds);
    pixels=imread(entry.imageFilename);if size(pixels,3)==1,pixels=repmat(pixels,1,1,3);end
    received=sample{1};if size(received,3)==1,received=repmat(received,1,1,3);end
    assert(isequal(pixels,received),'IDD:DatastoreImage','Datastore image differs from original.');
    r=records(find(string({records.ImageFile})==entry.imageFilename,1));
    assert(all(ismember(string(sample{3}),data.classes)),'IDD:DatastoreClass','Unexpected class.');
    expectedCount=0;
    for label=reshape(data.classes,1,[])
        expected=r.Boxes(r.Labels==label,:);actual=sample{2}(string(sample{3})==label,:);
        assert(isequal(sortrows(expected),sortrows(actual)),'IDD:DatastoreBox','Source/converted boxes or labels differ.');
        expectedCount=expectedCount+size(expected,1);
    end
    assert(size(sample{2},1)==expectedCount&&numel(sample{3})==expectedCount,'IDD:DatastoreCount','Labels/boxes misaligned.');
    if k<=10
        aug=augmentIDDTrainingData(sample,cfg);
        assert(isequal(aug{2},sample{2})&&isequal(aug{3},sample{3}),'IDD:Augmentation','Photometric augmentation changed geometry/labels.');
        pixels=aug{1};if ~isempty(aug{2}),pixels=insertObjectAnnotation(pixels,'rectangle',aug{2},cellstr(string(aug{3})));end
        pixels=insertText(pixels,[5 5],'GENUINE IDD - AUGMENTATION CHECK');
        imwrite(pixels,fullfile(augmentationDir,sprintf('%03d.png',k)));augmentedFiles(k)=entry.imageFilename;
    end
end
writetable(table((1:20).',sampleFiles,'VariableNames',{'SampleID','SourceImage'}),fullfile(cfg.outputDir,'datastore_validation_samples.csv'));
writetable(table((1:10).',augmentedFiles,'VariableNames',{'OverlayID','SourceImage'}),fullfile(augmentationDir,'source_manifest.csv'));
counts=data.classSummary;
% Keep the source-derived class inventory; aliases are not label-occurrence claims.
inventory=table(counts.OriginalLabel,counts.Instances,counts.Images,counts.CanonicalClass, ...
    repmat("MAPPED",height(counts),1),repmat("Observed accepted annotations; centralized semantic alias",height(counts),1), ...
    'VariableNames',{'IDDLabel','InstanceCount','ImageCount','MappedProjectClass','MappingStatus','Notes'});
inventory.MappingStatus(inventory.MappedProjectClass=="unknown")="UNSUPPORTED";
inventory.OfficialSplit=counts.Split;
writetable(inventory,fullfile(cfg.outputDir,'idd_class_inventory.csv'));
issues=data.conversionReport;writetable(issues,fullfile(cfg.outputDir,'annotation_validation_report.csv'));
files=data.inventory.files;split=["train";"val";"test"];images=zeros(3,1);annotations=images;
for k=1:3,images(k)=sum(files.Split==split(k)&files.ImageExists);annotations(k)=sum(files.Split==split(k)&files.AnnotationExists);end
writetable(table(split,images,annotations,'VariableNames',{'OfficialSplit','ExistingImageCount','ExistingAnnotationCount'}),fullfile(cfg.outputDir,'dataset_summary.csv'));
provenance=data.provenance;provenance.verifiedAnnotationImageCount=numel(records);
provenance.acceptedObjectCount=sum(arrayfun(@(r) size(r.Boxes,1),records));
provenance.annotationIssueCount=height(issues);
provenance.clippingIssueCount=sum(contains(issues.Reason,'clipped'));
provenance.rejectedAnnotationImageCount=numel(unique(issues.File(~contains(issues.Reason,'clipped'))));
provenance.countPolicy="Counts cover official-list files; accepted labels exclude rejected/difficult images. Test annotations unopened.";
save(fullfile(cfg.outputDir,'dataset_provenance.mat'),'provenance');
proof=struct('status',"PASS",'annotationOverlayCount',20,'augmentationOverlayCount',10, ...
    'datastoreSamples',20,'annotationDirectory',annotationDir,'augmentationDirectory',augmentationDir, ...
    'provenance',provenance,'visualReview',"PENDING HUMAN REVIEW BEFORE COMPETITION USE");
end
