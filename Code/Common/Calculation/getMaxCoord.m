% --- retrieves the coordinates of the maximum location from I
function pMax = getMaxCoord(I)

pMax = zeros(1,2);
[pMax(2),pMax(1)] = ind2sub(size(I),argMax(I(:)));  
