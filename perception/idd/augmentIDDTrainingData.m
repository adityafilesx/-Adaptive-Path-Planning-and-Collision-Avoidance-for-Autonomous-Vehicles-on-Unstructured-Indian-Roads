function data = augmentIDDTrainingData(data,cfg)
%AUGMENTIDDTRAININGDATA Conservative photometry; optional box-consistent reflection.
image=data{1};boxes=data{2};labels=data{3};
if size(image,3)==1,image=repmat(image,1,1,3);end
if rand<cfg.augmentation.flipProbability
    image=fliplr(image);boxes(:,1)=size(image,2)-boxes(:,1)-boxes(:,3)+2;
end
value=im2double(image);contrast=1+cfg.augmentation.contrast*(2*rand-1);
value=(value-.5)*contrast+.5+cfg.augmentation.brightness*(2*rand-1);
image=im2uint8(min(1,max(0,value)));
[boxes,valid]=validateIDDBoxes(boxes,size(image));
data={image,boxes(valid,:),labels(valid,:)};
end
