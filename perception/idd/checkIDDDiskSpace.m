function report = checkIDDDiskSpace(path,minimumGB,failIfLow)
%CHECKIDDDISKSPACE Check the actual destination volume, including external disks.
if nargin<3,failIfLow=false;end
path=iddCanonicalPath(path);probe=path;
while ~isfolder(probe)
    parent=string(fileparts(probe));if parent==probe||strlength(parent)==0,break;end
    probe=parent;
end
available=double(java.io.File(char(probe)).getUsableSpace())/1024^3;
report=struct('path',path,'volumeProbe',probe,'availableGB',available, ...
    'requiredGB',minimumGB,'sufficient',isfinite(available)&&available>=minimumGB);
if failIfLow && ~report.sufficient
    error('IDD:DiskSpace','Insufficient free space at %s: %.2f GiB available, %.2f required. No image copies or training started.',path,available,minimumGB);
end
end
