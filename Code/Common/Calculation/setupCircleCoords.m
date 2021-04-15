function pC = setupCircleCoords(p0,R,nXi)

% sets the input arguments
if (nargin < 3); nXi = 200; end

% calculates the circle x/y 
phi = linspace(0,2*pi,nXi)';
[dX,dY] = deal(R*cos(phi),R*sin(phi));

% sets the final coordinates
pC = [p0(1)+dX,p0(2)+dY];