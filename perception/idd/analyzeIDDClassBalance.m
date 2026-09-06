function counts = analyzeIDDClassBalance(records)
%ANALYZEIDDCLASSBALANCE Counts come only from successfully parsed actual objects.
labels=unique(vertcat(records.Labels));
rows=struct('OriginalLabel',{},'CanonicalClass',{},'Split',{},'Instances',{},'Images',{},'Frequency',{});
for split=["train","val"]
    selected=records(string({records.Split})==split);allLabels=vertcat(selected.Labels);
    for k=1:numel(labels)
        count=sum(allLabels==labels(k));images=sum(arrayfun(@(r) any(r.Labels==labels(k)),selected));
        rows(end+1)=struct('OriginalLabel',labels(k),'CanonicalClass',mapIDDClass(labels(k)), ...
            'Split',split,'Instances',count,'Images',images,'Frequency',count/max(1,numel(allLabels))); %#ok<AGROW>
    end
end
counts=struct2table(rows);
end
