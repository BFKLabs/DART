% --- removes the median baseline from the image, I
function ImdS = medianShiftImg(I)

ImdS = I - nanmedian(I(:));
