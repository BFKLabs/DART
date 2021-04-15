% --- resets an objects position so that it matches its proper extent --- %
function resetObjExtent(hObj)

% retrieves the object extent/position
[pExt,pPos] = deal(get(hObj,'Extent'),get(hObj,'Position'));

% updates the object location
set(hObj,'Position',[pPos(1:2) pExt(3) pPos(4)])