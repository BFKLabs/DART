% --- calculates an approximation of the ellipse perimeter
function P = calcEllipsePerim(MjAx,MnAx)

% scale factor
h = ((MjAx - MnAx).^2)/((MjAx + MnAx).^2);

% calculates the perimeter approimation
P = pi*(MjAx + MnAx)*(1 + (3*h)/(10 + sqrt(4-3*h)));