function cfg = applyRoadRunnerLocalConfiguration(cfg)
%APPLYROADRUNNERLOCALCONFIGURATION Merge optional machine-only settings.

    if nargin<1 || isempty(cfg), cfg=config(); end
    envRoot=string(getenv('SIH_ROADRUNNER_PROJECT_ROOT'));
    if strlength(strtrim(envRoot))>0 && strlength(string(cfg.roadrunner.projectRoot))==0
        cfg.roadrunner.projectRoot=char(envRoot);
    end
    envEnabled=lower(strtrim(string(getenv('SIH_ROADRUNNER_ENABLED'))));
    if any(envEnabled==["1","true","yes","on"]), cfg.roadrunner.enabled=true; end
    if exist('roadrunnerLocalConfig','file')==2
        local=roadrunnerLocalConfig();
        if ischar(local)||isstring(local)
            if isempty(cfg.roadrunner.projectRoot), cfg.roadrunner.projectRoot=char(local); end
        elseif isstruct(local)
            names=fieldnames(local);
            for i=1:numel(names)
                if isfield(cfg.roadrunner,names{i})
                    cfg.roadrunner.(names{i})=local.(names{i});
                end
            end
        end
    end
end
