function summary = summarizeRoadRunnerValidation(architecture, runtimeResults)
%SUMMARIZEROADRUNNERVALIDATION Keep architecture and runtime status separate.

    if nargin<2, runtimeResults=struct([]); end
    summary=struct('architectureStatus',"INCOMPLETE", ...
        'runtimeValidationStatus',"PENDING",'runtimeResults',runtimeResults, ...
        'architecture',architecture,'metrics',emptyRoadRunnerMetrics());
    if architecture.passed, summary.architectureStatus="COMPLETE"; end
    if isempty(runtimeResults), return; end
    statuses=string({runtimeResults.status});
    if all(statuses=="PASS")
        summary.runtimeValidationStatus="PASS";
    elseif any(statuses=="FAIL")
        summary.runtimeValidationStatus="FAIL";
    else
        summary.runtimeValidationStatus="PENDING";
    end
    if isscalar(runtimeResults), summary.metrics=runtimeResults.metrics; end
end
