% --- calculates the x-correlation sum image
function Z = calcXCorrSum(I,ITx,ITy,D)

% calculates the x/y-gradient x-correlation sum
[Gx,Gy] = imgradientxy(I,'Sobel');
Z = 0.5*(calcXCorr(ITx,Gx,D) + calcXCorr(ITy,Gy,D));