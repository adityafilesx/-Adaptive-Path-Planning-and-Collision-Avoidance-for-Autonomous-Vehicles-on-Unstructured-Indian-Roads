function mapping = getIDDClassMapping()
%GETIDDCLASSMAPPING Semantic aliases, NOT evidence that any class exists in IDD.
original=["car";"bus";"truck";"autorickshaw";"auto-rickshaw";"auto rickshaw"; ...
    "auto";"person";"pedestrian";"motorcycle";"motorbike";"two-wheeler"; ...
    "bicycle";"animal";"cattle";"unknown"];
canonical=["car";"bus";"truck";"auto";"auto";"auto";"auto";"pedestrian"; ...
    "pedestrian";"motorcycle";"motorcycle";"two-wheeler";"bicycle";"animal";"cattle";"unknown"];
mapping=table(original,canonical,'VariableNames',{'OriginalLabel','CanonicalClass'});
% cattle is mapped ONLY for an actually observed literal cattle label. Animal
% is never specialized to cattle; rider/pushcart/fallback objects stay unknown.
end
