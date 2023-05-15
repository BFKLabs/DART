% --- creates the polar plot patch
function hPP = createPolarPlotPatch(hAx,Phi,R,dPhi,iCol)

% parameters
d2r = pi/180;
if (nargin < 5)
    [iCol,col] = deal(1,{'r'});
else
    col = {'g','b'};
end

% sets the lower/upper 
phiLo = (90-(Phi-dPhi/2))*d2r;
phiMid = (90-Phi)*d2r;
phiHi = (90-(Phi+dPhi/2))*d2r;

% sets the polar segment patch coordinates/cdata
phiT = [phiLo,phiMid,phiHi];
[xP,yP] = deal([0 R*cos(phiT)],[0 R*sin(phiT)]);    

% creates the new patch
hPP = patch(xP,yP,col{iCol},'edgecolor',col{iCol});    
set(hPP,'parent',hAx)     