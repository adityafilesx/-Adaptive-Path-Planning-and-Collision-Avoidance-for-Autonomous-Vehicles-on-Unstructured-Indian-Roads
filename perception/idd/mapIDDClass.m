function canonical = mapIDDClass(label)
mapping=getIDDClassMapping();labels=lower(strtrim(string(label)));
canonical=repmat("unknown",size(labels));
for k=1:numel(labels),i=find(mapping.OriginalLabel==labels(k),1);if ~isempty(i),canonical(k)=mapping.CanonicalClass(i);end,end
end
