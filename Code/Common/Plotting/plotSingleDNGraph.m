% --- creates the day/night background for a single day
function plotSingleDNGraph(yLim,p)

% parameters and other initialisations
[ix,iy,fAlpha] = deal([1 1 2 2],[1 2 2 1],0.9);
[xFillD,xFillN,yFill] = deal([0 p.hDay],[p.hDay 24],yLim*[0 1]);

% creates the fill objects
fill(xFillD(ix),yFill(iy),'y','FaceAlpha',fAlpha,'tag','hDN')
fill(xFillN(ix),yFill(iy),'k','FaceAlpha',fAlpha/2,'tag','hDN')   