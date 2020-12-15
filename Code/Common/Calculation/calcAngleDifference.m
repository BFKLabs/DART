function dPhi = calcAngleDifference(Phi1,Phi2,varargin)

%
if (nargin == 1)
    PhiT = Phi1;
    [Phi1,Phi2] = deal(PhiT(1:end-1),PhiT(2:end));
end
    
dPhi = atan2(sin(Phi1-Phi2),cos(Phi1-Phi2));
if (nargin == 3); dPhi = dPhi*180/pi; end
