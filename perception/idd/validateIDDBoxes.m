function [clipped,valid] = validateIDDBoxes(boxes,imageSize)
%VALIDATEIDDBOXES MATLAB one-based [x y width height], inclusive pixel limits.
assert(isnumeric(boxes)&&size(boxes,2)==4,'IDD:Boxes','Boxes must be N-by-4.');
assert(numel(imageSize)>=2&&all(isfinite(imageSize(1:2)))&&all(imageSize(1:2)>0),'IDD:ImageSize','Invalid image size.');
boxes=double(boxes);valid=all(isfinite(boxes),2)&all(boxes(:,3:4)>0,2);
right=min(imageSize(2),boxes(:,1)+boxes(:,3)-1);bottom=min(imageSize(1),boxes(:,2)+boxes(:,4)-1);
left=max(1,boxes(:,1));top=max(1,boxes(:,2));
clipped=[left top right-left+1 bottom-top+1];valid=valid&all(clipped(:,3:4)>0,2);
clipped(~valid,:)=NaN;
end
