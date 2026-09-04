% testPerception.m
% Executable validation for the synthetic perception layer.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(projectRoot));
cfg = config();

groundTruth(1) = struct('ID', 11, 'ClassID', 1, ...
    'Position', [10 0 0], 'Velocity', [4 0 0]); %#ok<SAGROW>
groundTruth(2) = struct('ID', 12, 'ClassID', 1, ...
    'Position', [80 0 0], 'Velocity', [3 0 0]); %#ok<SAGROW>
egoState = struct('Position', [0 0 0], 'Velocity', [0 0 0]);

% Executes and repeats exactly with an explicit seed.
first = simulatePerception(groundTruth, egoState, cfg);
second = simulatePerception(groundTruth, egoState, cfg);
assert(isequaln(first, second), 'Same seed must reproduce detections.');

% A changed seed changes the synthetic noise realization.
otherCfg = cfg;
otherCfg.perception.randomSeed = cfg.perception.randomSeed + 1;
third = simulatePerception(groundTruth, egoState, otherCfg);
assert(~isequaln(first, third), 'Different seeds must change detections.');

% With nonzero noise and no misses, observations differ from truth.
noiseCfg = cfg;
noiseCfg.perception.missedDetectionProbability = 0;
noiseCfg.perception.classificationConfusionProbability = 0;
noisy = simulatePerception(groundTruth, egoState, noiseCfg);
assert(any(abs(noisy(1).Position - groundTruth(1).Position) > 0), ...
    'Nonzero position noise must perturb an observation.');

% A positive (here certain) missed-detection probability produces misses.
missCfg = cfg;
missCfg.perception.missedDetectionProbability = 1;
missed = simulatePerception(groundTruth, egoState, missCfg);
assert(all(~[missed.IsDetected]), 'Configured misses must occur.');

% Farther actors receive greater configured uncertainty.
assert(all(first(2).PositionStd > first(1).PositionStd), ...
    'Position uncertainty must increase after the configured distance.');
assert(all(first(2).VelocityStd > first(1).VelocityStd), ...
    'Velocity uncertainty must increase after the configured distance.');

assert(all([first.Confidence] >= 0 & [first.Confidence] <= 1), ...
    'Confidence must remain within [0, 1].');

% Class truth is retained while a synthetic perceived class may differ.
classCfg = cfg;
classCfg.perception.missedDetectionProbability = 0;
classCfg.perception.classificationConfusionProbability = 1;
classCfg.perception.classLabels = [1 2];
confused = simulatePerception(groundTruth, egoState, classCfg);
assert(all([confused.TrueClass] == 1), 'TrueClass must preserve ground truth.');
assert(all([confused.PerceivedClass] == 2), ...
    'PerceivedClass must be separately perturbable.');

disp('testPerception: all checks passed.');
