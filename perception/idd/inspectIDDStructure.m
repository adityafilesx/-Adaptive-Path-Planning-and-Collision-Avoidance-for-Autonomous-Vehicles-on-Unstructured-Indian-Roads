function inventory = inspectIDDStructure(cfg)
%INSPECTIDDSTRUCTURE Respect explicit/official split lists; never repartition.
dataset=findIDDDataset(cfg);
assert(dataset.available,'IDD:DatasetRequired','%s',dataset.message);
assert(upper(string(cfg.annotationFormat))=="VOC_XML",'IDD:AnnotationFormat', ...
    'This adapter supports IDD-Detection VOC XML. JSON/segmentation variants require a reviewed adapter; no silent conversion.');
rows=struct('FrameName',{},'Split',{},'ImageFile',{},'AnnotationFile',{},'ImageExists',{},'AnnotationExists',{});
splitPaths=struct();
for split=["train","val","test"]
    path=string(cfg.(split+"List"));
    if strlength(path)>0
        if ~isfile(path),path=fullfile(dataset.root,path);end
    else
        candidates=[fullfile(dataset.root,'ImageSets','Main',split+".txt"), ...
            fullfile(dataset.root,split+".txt")];
        found=find(isfile(candidates),1);if ~isempty(found),path=candidates(found);end
    end
    if strlength(path)==0||~isfile(path)
        assert(split=="test",'IDD:SplitRequired','Official %s list missing. Configure %sList; do not randomly split.',split,split);
        splitPaths.(split)="";continue
    end
    splitPaths.(split)=iddCanonicalPath(path);
    ids=strtrim(readlines(path));ids=ids(strlength(ids)>0);
    assert(~isempty(ids),'IDD:EmptySplit','Split %s is empty.',split);
    for k=1:numel(ids)
        id=replace(ids(k),'\','/');
        assert(~contains(id,"..")&&~startsWith(id,"/")&&~contains(id,":"),'IDD:PathTraversal','Invalid relative image identifier: %s',id);
        assert(isempty(regexp(char(id),'\s','once')),'IDD:SplitFormat','Expected one relative image ID per line, not a class-specific split list.');
        if startsWith(id,"JPEGImages/"),id=extractAfter(id,strlength("JPEGImages/"));end
        [folder,name,ext]=fileparts(id);if strlength(ext)==0,ext='.jpg';end
        relative=fullfile(folder,name+string(ext));
        imageRoot=iddCanonicalPath(fullfile(dataset.root,cfg.imageFolder));
        annotationRoot=iddCanonicalPath(fullfile(dataset.root,cfg.annotationFolder));
        project=lower(iddCanonicalPath(cfg.projectRoot));
        assert(~any(lower([imageRoot annotationRoot])==project|startsWith(lower([imageRoot annotationRoot]),project+filesep)), ...
            'IDD:DatasetInRepository','Dataset image/annotation directories must remain outside the repository, including symlinks.');
        im=iddCanonicalPath(fullfile(imageRoot,relative));
        annotation=iddCanonicalPath(fullfile(annotationRoot,folder,name+".xml"));
        assert(startsWith(lower(im),lower(imageRoot+filesep))&&startsWith(lower(annotation),lower(annotationRoot+filesep)), ...
            'IDD:PathTraversal','Resolved file escapes dataset directories.');
        rows(end+1)=struct('FrameName',string(relative),'Split',split,'ImageFile',im, ...
            'AnnotationFile',annotation,'ImageExists',isfile(im),'AnnotationExists',isfile(annotation)); %#ok<AGROW>
    end
end
inventory=struct('dataset',dataset,'files',struct2table(rows),'splitFiles',splitPaths);
paths=lower(inventory.files.ImageFile);
assert(numel(unique(paths))==numel(paths),'IDD:SplitLeakage','Duplicate image/symlink target within or across official splits.');
assert(any(inventory.files.Split=="train"&inventory.files.ImageExists)&&any(inventory.files.Split=="val"&inventory.files.ImageExists), ...
    'IDD:NoImages','Configured splits contain no usable training/validation images.');
inventory.provenance=struct('datasetName',"India Driving Dataset",'datasetVariant',string(cfg.variant), ...
    'source',string(cfg.source),'datasetRoot',dataset.root,'timestamp',string(datetime('now')), ...
    'annotationVersion',string(cfg.annotationVersion),'classHierarchy',string(cfg.classHierarchy), ...
    'annotationLabelField',string(cfg.labelField),'annotationFormat',string(cfg.annotationFormat), ...
    'trainCount',sum(inventory.files.Split=="train"&inventory.files.ImageExists), ...
    'validationCount',sum(inventory.files.Split=="val"&inventory.files.ImageExists), ...
    'testCount',sum(inventory.files.Split=="test"&inventory.files.ImageExists), ...
    'testLabelsUsed',false,'splitPolicy',"Official lists; no random repartition", ...
    'matlabVersion',string(version),'toolboxVersions',ver);
end
