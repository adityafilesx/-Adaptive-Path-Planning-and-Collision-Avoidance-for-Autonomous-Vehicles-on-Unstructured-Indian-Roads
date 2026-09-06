function [records,report] = parseIDDAnnotations(inventory,cfg)
%PARSEIDDANNOTATIONS Read actual VOC objects; no fabricated images/boxes/labels.
checkIDDDiskSpace(cfg.outputDir,cfg.minimumConversionFreeGB,true);
rows=struct('FrameName',{},'Split',{},'ImageFile',{},'AnnotationFile',{},'ImageSize',{},'Boxes',{},'Labels',{});
issues=struct('File',{},'Object',{},'Reason',{});files=inventory.files;
for i=1:height(files)
    if files.Split(i)=="test",continue;end % hidden/unavailable test labels are never opened
    file=files.AnnotationFile(i);
    if ~files.ImageExists(i)||~files.AnnotationExists(i),addIssue(0,"Missing image or annotation; image excluded");continue;end
    try
        meta=imfinfo(files.ImageFile(i));imageSize=[meta(1).Height meta(1).Width 3];
        xml=fileread(file);
        assert(~contains(upper(xml),'<!DOCTYPE')&&~contains(upper(xml),'<!ENTITY'),'IDD:XML','External XML entities are not allowed.');
        doc=xmlread(char(file));objects=doc.getElementsByTagName('object');
        boxes=zeros(0,4);labels=strings(0,1);bad=false;
        for j=0:objects.getLength()-1
            obj=objects.item(j);
            if ~cfg.includeDifficult&&value(obj,'difficult',"0")=="1",addIssue(j+1,"Difficult object: entire image excluded to avoid unlabelled positives");bad=true;continue;end
            label=value(obj,char(cfg.labelField),"");b=obj.getElementsByTagName('bndbox');
            if strlength(label)==0||b.getLength()~=1,addIssue(j+1,"Missing/ambiguous label or bounding box");bad=true;continue;end
            node=b.item(0);xy=[number(node,'xmin') number(node,'ymin') number(node,'xmax') number(node,'ymax')];
            raw=[xy(1:2) xy(3:4)-xy(1:2)+1];[clipped,ok]=validateIDDBoxes(raw,imageSize);
            if ~ok,addIssue(j+1,"Invalid finite/positive/in-image box");bad=true;continue;end
            if ~isequal(raw,clipped),addIssue(j+1,"Box clipped to image bounds");end
            boxes(end+1,:)=clipped;labels(end+1,1)=strtrim(label); %#ok<AGROW>
        end
        if bad,addIssue(0,"Incomplete usable annotations; entire image excluded, not used as a negative");continue;end
        rows(end+1)=struct('FrameName',files.FrameName(i),'Split',files.Split(i), ...
            'ImageFile',files.ImageFile(i),'AnnotationFile',file,'ImageSize',imageSize, ...
            'Boxes',boxes,'Labels',labels); %#ok<AGROW>
    catch info,addIssue(0,"Image/annotation rejected: "+string(info.message));end
end
records=rows(:);report=struct2table(issues);
    function addIssue(object,reason)
        issues(end+1)=struct('File',file,'Object',object,'Reason',string(reason));
    end
end
function text=value(node,name,fallback)
nodes=node.getElementsByTagName(name);text=fallback;
if nodes.getLength()==1,text=strtrim(string(nodes.item(0).getTextContent()));end
end
function x=number(node,name)
x=str2double(value(node,name,"NaN"));
end
