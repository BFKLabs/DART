% --- retrieves the original object dimensions
function objDim0 = getInitObjDim(hFig)

% retrieves the handles of objects within the figure
hObj = findall(hFig);

% removes the menu/toolbar items from the list
hObjM = findall(hObj,'Type','uimenu');
hObjT = findall(hObj,'Type','uitoolbar');
hObjTT = findall(hObj,'Type','uitoggletool');
hObj = setdiff(hObj,[hObjM;hObjT;hObjTT]);

% returns the object handles and position vectors
objDim0 = {num2cell(hObj),get(hObj,'Position')};