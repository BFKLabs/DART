% --- calculates the circle coordindates
function [XC,YC] = calcCircleCoords(aP,iFly,iApp)

% sets the circle radius
if numel(aP.R) == 1
    R = aP.R;
else
    R = aP.R(iFly,iApp);
end

% calculates the circle coordinates
phi = linspace(0,2*pi,101)';
[XC,YC] = deal(R*cos(phi),R*sin(phi));