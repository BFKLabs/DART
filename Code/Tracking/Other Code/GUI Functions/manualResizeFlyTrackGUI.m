function manualResizeFlyTrackGUI(hFig,objDim,objVal,varargin)

% removes the resize callback function
resizeFcn = get(hFig,'SizeChangedFcn');
set(hFig,'SizeChangedFcn',[]);

% sets the figure dimensions
if nargin == 3
    resetObjPos(hFig,objDim,objVal)
else
    resetObjPos(hFig,objDim,objVal,1)
end

% resets the resize callback function
set(hFig,'SizeChangedFcn',resizeFcn);