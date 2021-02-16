function resizeFlyTrackGUI(hFig,szImg)

% parameters
dX = 10;

% if the image size is not provided, then retrieve the current
if ~exist('szImg','var')
    iData = getappdata(hFig,'iData');
    szImg = iData.sz;
end

% initialisations
hPanel = findall(hFig,'tag','panelImg');
hAx = findall(hPanel,'type','axes');

% sets the axis dimension units to normalised
hUnits = get(hAx,'Units');
set(hAx,'Units','Normalized');

% determines the change in dimensions
pPos = get(hPanel,'Position');
pWid = (szImg(2)/szImg(1))*pPos(4);

% resizes the objects
resetObjPos(hPanel,'width',pWid);
manualResizeFlyTrackGUI(hFig,'width',dX+pPos(1)+pWid);

% resets the resize function
set(hAx,'Units',hUnits);