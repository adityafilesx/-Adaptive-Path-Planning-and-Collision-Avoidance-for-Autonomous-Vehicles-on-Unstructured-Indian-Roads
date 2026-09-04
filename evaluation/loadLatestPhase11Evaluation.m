function [evaluation,sourceFile] = loadLatestPhase11Evaluation(outputRoot)
%LOADLATESTPHASE11EVALUATION Load newest timestamped Phase 11 evaluation.

    if nargin<1||isempty(outputRoot)
        root=fileparts(fileparts(mfilename('fullpath')));
        outputRoot=fullfile(root,'results','phase11');
    end
    files=dir(fullfile(outputRoot,'run_*','phase11Evaluation_*.mat'));
    if isempty(files),error('Phase11:NoSavedEvaluation','No saved Phase 11 evaluation exists.');end
    [~,order]=sort([files.datenum],'descend');file=files(order(1));
    sourceFile=string(fullfile(file.folder,file.name));loaded=load(sourceFile,'evaluation');
    evaluation=loaded.evaluation;
end
