function [robustness,sourceFile] = loadLatestPhase9Robustness()
%LOADLATESTPHASE9ROBUSTNESS Load newest stored robustness evidence by timestamp.

    root=fileparts(fileparts(mfilename('fullpath')));
    files=dir(fullfile(root,'results','phase9','phase9Robustness_*.mat'));
    if isempty(files),error('Phase11:MissingPhase9','No Phase 9 robustness result exists.');end
    [~,order]=sort([files.datenum],'descend'); file=files(order(1));
    sourceFile=string(fullfile(file.folder,file.name)); loaded=load(sourceFile,'robustness');
    assert(isfield(loaded,'robustness'),'Phase11:InvalidPhase9Result');
    robustness=loaded.robustness;
end
