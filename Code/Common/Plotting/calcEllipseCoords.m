function [xC,yC] = calcEllipseCoords(E)

% field retrieval
phiC = linspace(0,2*pi,101);
[A,B,phiR] = deal(E.l,E.w,E.theta);

% calculates the coordinates
xC = A*cos(phiC)*cos(phiR) - B*sin(phiC)*sin(phiR);
yC = B*cos(phiR)*sin(phiC) + A*cos(phiC)*sin(phiR);