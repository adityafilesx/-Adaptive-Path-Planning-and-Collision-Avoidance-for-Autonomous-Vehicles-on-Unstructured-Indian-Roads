function [canonicalClass, detail] = mapRoadRunnerActorClass(roadRunnerType, strict)
%MAPROADRUNNERACTORCLASS Central visual-to-algorithmic class mapping.

    if nargin < 2, strict = false; end
    original = string(roadRunnerType);
    key = lower(regexprep(strtrim(original), '[^a-zA-Z0-9]+', ''));
    supported = ["car","bus","truck","auto","motorcycle", ...
        "two_wheeler","bicycle","pedestrian","pushcart", ...
        "animal","cattle","unknown"];
    if any(contains(key, ["pushcart","handcart","vendorcart"]))
        canonicalClass = "pushcart";
    elseif any(contains(key, ["autorickshaw","rickshaw","tuktuk","auto"]))
        canonicalClass = "auto";
    elseif any(contains(key, ["motorcycle","motorbike","scooter"]))
        canonicalClass = "motorcycle";
    elseif any(contains(key, ["twowheeler","2wheeler"]))
        canonicalClass = "two_wheeler";
    elseif any(contains(key, ["bicycle","cyclist","cycle","bike"]))
        canonicalClass = "bicycle";
    elseif any(contains(key, ["pedestrian","person","human","character","citizen"]))
        canonicalClass = "pedestrian";
    elseif any(contains(key, ["cattle","cow","bull","buffalo"]))
        canonicalClass = "cattle";
    elseif any(contains(key, ["animal","livestock"]))
        canonicalClass = "animal";
    elseif contains(key, "bus")
        canonicalClass = "bus";
    elseif any(contains(key, ["truck","lorry"]))
        canonicalClass = "truck";
    elseif any(contains(key, ["car","sedan","suv","vehicle","van","hatchback"]))
        canonicalClass = "car";
    elseif any(strcmp(key, erase(supported, "_")))
        canonicalClass = supported(find(strcmp(key, erase(supported, "_")), 1));
    else
        canonicalClass = "unknown";
    end
    usedFallback = canonicalClass == "unknown";
    if strict && usedFallback
        error('RoadRunner:UnknownActorClass', ...
            'No canonical class mapping exists for RoadRunner type "%s".', original);
    end
    detail = struct('input', original, 'normalizedInput', key, ...
        'canonicalClass', canonicalClass, 'usedFallback', usedFallback, ...
        'supportedClasses', supported);
end
