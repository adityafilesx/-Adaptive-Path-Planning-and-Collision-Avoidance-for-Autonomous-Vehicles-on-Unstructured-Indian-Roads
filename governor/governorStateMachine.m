function newState = governorStateMachine(totalRisk, previousState, cfg)
%GOVERNORSTATEMACHINE Hysteresis-based ACARG state transition logic.
%   Prevents oscillation between states by using separate enter/exit
%   thresholds.  State transitions require risk to cross a higher enter
%   threshold to escalate, but only drop back when risk falls below a
%   lower exit threshold.
%
%   States:
%       'NORMAL'             — nominal driving
%       'CAUTIOUS'           — enlarged safety envelope, reduced speed
%       'CONSERVATIVE_STOP'  — maximum inflation, near-stop speed scale
%
%   Thresholds from cfg.governor.thresholds:
%       cautiousEnter / cautiousExit
%       conservativeEnter / conservativeExit

    gcfg = governorSubConfig(cfg, 'thresholds');
    if ~ischar(previousState) && ~isstring(previousState)
        previousState = 'NORMAL';
    end
    previousState = upper(char(previousState));

    switch previousState
        case 'NORMAL'
            if totalRisk >= gcfg.cautiousEnter
                if totalRisk >= gcfg.conservativeEnter
                    newState = 'CONSERVATIVE_STOP';
                else
                    newState = 'CAUTIOUS';
                end
            else
                newState = 'NORMAL';
            end

        case 'CAUTIOUS'
            if totalRisk >= gcfg.conservativeEnter
                newState = 'CONSERVATIVE_STOP';
            elseif totalRisk <= gcfg.cautiousExit
                newState = 'NORMAL';
            else
                newState = 'CAUTIOUS';
            end

        case 'CONSERVATIVE_STOP'
            if totalRisk <= gcfg.conservativeExit
                if totalRisk <= gcfg.cautiousExit
                    newState = 'NORMAL';
                else
                    newState = 'CAUTIOUS';
                end
            else
                newState = 'CONSERVATIVE_STOP';
            end

        otherwise
            newState = 'NORMAL';
    end
end

%% ---- local helpers ----

function gcfg = governorSubConfig(cfg, subField)
    if isfield(cfg, 'governor') && isfield(cfg.governor, subField)
        gcfg = cfg.governor.(subField);
    else
        error('governorStateMachine:MissingConfig', ...
            'cfg.governor.%s is required.', subField);
    end
end
