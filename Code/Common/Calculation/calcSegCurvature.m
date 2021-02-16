% --- calculates the curvature of the sub-sequence
function K = calcSegCurvature(p,Kmax)

% initialisations
xi = (1:size(p,1))';

% sets up the piecewise polynomial structs
[pX,pY] = deal(pchip(xi,p(:,1)),pchip(xi,p(:,2)));
[dpX,dpY] = deal(fnder(pX),fnder(pY));
[d2pX,d2pY] = deal(fnder(pX,2),fnder(pY,2));

% calculates the segment curvature
[dpXi,dpYi] = deal(ppval(dpX,xi),ppval(dpY,xi)); 
K = (dpXi.*ppval(d2pY,xi)-dpYi.*ppval(d2pX,xi))./((dpXi.^2+dpYi.^2).^(3/2));

if (nargin == 2)
    K(isnan(K)) = Kmax;
    ii = abs(K) > Kmax;
    K(ii) = sign(K(ii)).*Kmax;
else
    K(isnan(K)) = inf;
end