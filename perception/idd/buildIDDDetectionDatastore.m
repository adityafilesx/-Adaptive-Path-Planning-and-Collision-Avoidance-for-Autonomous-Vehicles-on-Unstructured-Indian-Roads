function [ds,images,boxes] = buildIDDDetectionDatastore(trainingTable)
%BUILDIDDDETECTIONDATASTORE MATLAB's three-column image/box/categorical contract.
assert(height(trainingTable)>0&&width(trainingTable)>1,'IDD:Datastore','Empty detection training table.');
assert(all(isfile(trainingTable.imageFilename)),'IDD:MissingImage','Referenced image is absent.');
images=imageDatastore(cellstr(trainingTable.imageFilename));
boxes=boxLabelDatastore(trainingTable(:,2:end));ds=combine(images,boxes);
end
