% --- creates the polar plot patch
function createPolarPlotPatch(hAx,Phi,R,dPhi,iCol)

% parameters
d2r = pi/180;
if (nargin < 5)
    [iCol,col] = deal(1,{'r'});
else
    col = {'g','b'};
end

% sets the lower/upper 
phiLo = (90-(Phi-dPhi/2))*d2r;
phiHi = (90-(Phi+dPhi/2))*d2r;

% sets the polar segment patch coordinates/cdata
xP = [0 R*cos([phiLo,phiHi])];
yP = [0 R*sin([phiLo,phiHi])];    

% creates the new patch
hPP = patch(xP,yP,col{iCol},'edgecolor',col{iCol});    
set(hPP,'parent',hAx)     