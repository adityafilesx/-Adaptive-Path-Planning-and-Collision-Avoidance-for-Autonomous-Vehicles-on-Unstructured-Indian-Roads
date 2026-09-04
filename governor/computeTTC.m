function cpa = computeTTC(actorPos, actorVel, egoPos, egoVel)
%COMPUTETTC 2D closest-point-of-approach (CPA) between ego and actor.
%   Returns a struct with:
%       tCPA          — time to closest approach (s, >= 0)
%       dCPA          — distance at closest approach (m)
%       relativeSpeed — magnitude of relative velocity (m/s)
%       isClosing     — true if actor is currently approaching ego
%
%   Uses the analytic CPA formula:
%       r = p_actor - p_ego
%       v = v_actor - v_ego
%       t_CPA = max(0, -dot(r,v) / dot(v,v))
%       d_CPA = ||r + v * t_CPA||
%
%   Handles zero/near-zero relative velocity, NaN, and Inf robustly.

    r = safeVec2(actorPos) - safeVec2(egoPos);
    v = safeVec2(actorVel) - safeVec2(egoVel);

    vSquared = dot(v, v);
    relativeSpeed = sqrt(max(0, vSquared));

    if vSquared < eps
        % Nearly stationary relative motion — CPA is now
        cpa = struct('tCPA', 0, 'dCPA', norm(r), ...
            'relativeSpeed', 0, 'isClosing', false);
        return;
    end

    tCPA = max(0, -dot(r, v) / vSquared);   % only future CPA
    closestSeparation = r + v * tCPA;
    dCPA = norm(closestSeparation);
    isClosing = dot(r, v) < 0;               % negative dot = approaching

    cpa = struct('tCPA', tCPA, 'dCPA', dCPA, ...
        'relativeSpeed', relativeSpeed, 'isClosing', isClosing);
end

%% ---- local helpers ----

function vec = safeVec2(value)
%SAFEVEC2 Ensure a finite 1x2 row vector.
    value = double(value(:).');
    if numel(value) < 2
        vec = [0 0];
    else
        vec = value(1:2);
    end
    vec(~isfinite(vec)) = 0;
end
