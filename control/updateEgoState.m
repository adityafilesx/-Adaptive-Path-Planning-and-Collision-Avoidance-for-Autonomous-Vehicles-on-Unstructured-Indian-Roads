function [nextState, command] = updateEgoState(egoState, steering, desiredSpeed, cfg)
%UPDATEEGOSTATE Apply bounded proportional speed control and bicycle motion.

    acceleration = cfg.control.speedControlGain * (desiredSpeed - egoState.speed);
    acceleration = min(cfg.control.maxAcceleration, ...
        max(-cfg.control.maxDeceleration, acceleration));
    [nextState, applied] = kinematicBicycleStep(egoState, steering, ...
        acceleration, cfg);
    command = applied;
    command.desiredSpeed = desiredSpeed;
end
