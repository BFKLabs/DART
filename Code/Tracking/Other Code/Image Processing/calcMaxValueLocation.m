% --- calculates the location of the maximum 
function [Pmx,Imx] = calcMaxValueLocation(I,type)

% sets the function type
if (nargin == 1); type = 'max'; end

% calculates the value/location of the maximum point
[Imx,imx] = feval(type,I(:));

% returns the coordinates/max value in a single array
[ymx,xmx] = ind2sub(size(I),imx);
Pmx = [xmx,ymx];