function desiredSpeed = desiredSpeedForACARG(acarg, cfg)
%DESIREDSPEEDFORACARG Convert the governor decision into physical speed.

    if strcmp(acarg.state, 'CONSERVATIVE_STOP')
        desiredSpeed = 0;
    else
        desiredSpeed = cfg.control.baseSpeed * acarg.speedScale;
    end
    desiredSpeed = max(0, desiredSpeed);
end
