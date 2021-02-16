% --- calculates the median baseline removal neighbourhood size
function h0 = getMedBLSize(iMov)

% calculates the median baseline removal neighbourhood
if is2DCheck(iMov)
    pW = 2/3;
    h0 = ceil(pW*median(cellfun(@length,iMov.iRT{1})));               
else
    h0 = 50;
end