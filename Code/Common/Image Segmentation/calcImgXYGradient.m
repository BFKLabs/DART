% --- calculates the 2D gradient of an image array, I
function IG = calcImgXYGradient(I)

% calculates the coarse residual gradient
[Gx,Gy] = imgradientxy(I,'prewitt'); 
IG = abs(Gy) + abs(Gx);