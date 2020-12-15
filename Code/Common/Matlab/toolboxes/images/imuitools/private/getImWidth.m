function imageWidth = getImWidth(hIm)
%getImWidth returns the overall spatial width of an R-Set or non-R-Set
%image.
%
% imageWidth = getImWidth(hIm) returns the spatial width of the image
% hIm. 

%   Copyright 2008 The MathWorks, Inc.

if isRSetImage(hIm)
    imageWidth = getSpatialDims(hIm);
else
    img = get(hIm,'cdata');
    imageWidth = size(img,2);
end
