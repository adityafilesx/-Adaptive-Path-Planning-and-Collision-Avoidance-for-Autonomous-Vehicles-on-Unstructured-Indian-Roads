function metrics = compareRoadRunnerSceneCorrespondence(actors, manifest)
%COMPAREROADRUNNERSCENECORRESPONDENCE Check behavioural state correspondence.

    countMismatch = numel(actors)-numel(manifest.actors);
    idMismatch = 0; classMismatch = 0;
    positionErrors = NaN(1,numel(manifest.actors));
    speedErrors = NaN(1,numel(manifest.actors));
    yawErrors = NaN(1,numel(manifest.actors));
    for i=1:numel(manifest.actors)
        expected=manifest.actors(i);
        idx=find([actors.ID]==expected.logicalActorID,1);
        if isempty(idx), idMismatch=idMismatch+1; continue; end
        actual=actors(idx);
        if ~strcmpi(actual.Class,expected.canonicalClass), classMismatch=classMismatch+1; end
        expectedPosition=[expected.initialPose.x expected.initialPose.y expected.initialPose.z];
        expectedVelocity=[expected.velocity.x expected.velocity.y expected.velocity.z];
        positionErrors(i)=norm(actual.Position-expectedPosition);
        speedErrors(i)=norm(actual.Velocity-expectedVelocity);
        yawErrors(i)=abs(atan2(sin(actual.Yaw-expected.initialPose.yaw), ...
            cos(actual.Yaw-expected.initialPose.yaw)));
    end
    metrics=struct('statePositionError',maxFinite(positionErrors), ...
        'yawError',maxFinite(yawErrors),'speedError',maxFinite(speedErrors), ...
        'actorCountMismatch',countMismatch, ...
        'ActorIDMismatchCount',idMismatch,'classMismatchCount',classMismatch, ...
        'corresponds',countMismatch==0 && idMismatch==0 && classMismatch==0 && ...
            maxFinite(positionErrors)<0.25 && maxFinite(speedErrors)<0.25 && ...
            maxFinite(yawErrors)<deg2rad(2));
end
function value=maxFinite(values)
values=values(isfinite(values));
if isempty(values), value=Inf; else, value=max(values); end
end
