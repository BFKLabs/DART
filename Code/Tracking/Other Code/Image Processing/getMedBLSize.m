% --- calculates the median baseline removal neighbourhood size
function h0 = getMedBLSize(iMov)

%
if isfield(iMov,'is2D')
    is2D = iMov.is2D;
else
    is2D = is2DCheck(iMov);
end

% calculates the median baseline removal neighbourhood
if is2D
    pW = 2/3;
    h0 = ceil(pW*median(cellfun('length',iMov.iRT{1})));
else
    h0 = 50;
end
