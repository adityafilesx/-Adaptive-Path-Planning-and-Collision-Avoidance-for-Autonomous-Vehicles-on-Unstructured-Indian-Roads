function states = extractPathStates(nativePath)
%EXTRACTPATHSTATES Normalize a navPath or compatible result to N-by-3 poses.

    if isempty(nativePath)
        states = zeros(0, 3);
    elseif isnumeric(nativePath)
        states = nativePath;
    elseif isobject(nativePath) && isprop(nativePath, 'States')
        states = nativePath.States;
    elseif isstruct(nativePath) && isfield(nativePath, 'States')
        states = nativePath.States;
    else
        error('extractPathStates:UnsupportedPath', ...
            'Planner output does not expose a States representation.');
    end
    if isempty(states)
        states = zeros(0, 3);
        return;
    end
    if size(states, 2) < 3
        error('extractPathStates:InvalidStates', ...
            'Path states must include x, y, and theta columns.');
    end
    states = double(states(:, 1:3));
end
