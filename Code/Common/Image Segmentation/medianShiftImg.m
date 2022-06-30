% --- removes the median baseline from the image, I
function ImdS = medianShiftImg(I)

ImdS = I - median(I(:),'omitnan');
