function report = setupRoadRunnerWindows(cfg)
%SETUPROADRUNNERWINDOWS Read-only setup audit; installs or creates nothing.

    if nargin<1 || isempty(cfg), cfg=applyRoadRunnerLocalConfiguration(config()); end
    report=validateRoadRunnerEnvironment(cfg);
    c=report.capability;
    fprintf('RoadRunner target setup audit\n');
    fprintf('Platform: %s | supported: %s\n',c.platform,yesNo(c.platformSupported));
    fprintf('MATLAB RoadRunner API found: %s\n',yesNo(c.matlabAPIFound));
    fprintf('Project configured: %s | source: %s\n', ...
        yesNo(c.projectConfigured),c.paths.projectRootSource);
    if c.projectConfigured, fprintf('Project root: %s\n',c.paths.projectRoot); end
    fprintf('Expected project folders found: %s\n',yesNo(c.requiredFoldersFound));
    fprintf('Integration enabled: %s\n',yesNo(c.executionEnabled));
    fprintf('Status: %s\n',c.reason);
    if ismac
        fprintf('RoadRunner runtime validation cannot execute on this platform.\n');
    elseif ~c.runtimeReady
        fprintf('Resolve the reported prerequisites; this script does not install software.\n');
    else
        fprintf('Runtime prerequisites are ready. Run tests/testRoadRunnerIntegration.m.\n');
    end
end
function value=yesNo(flag)
if flag, value='YES'; else, value='NO'; end
end
