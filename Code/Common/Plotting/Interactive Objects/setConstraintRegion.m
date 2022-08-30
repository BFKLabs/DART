function setConstraintRegion(hObj,xLim,yLim,isOld,objType)

% sets the default input arguments
if ~exist('isOld','var'); isOld = isOldIntObjVer(); end

if isOld
    % case is the old format objects

    % sets the interactive object type string
    tStr = sprintf('im%s',objType);
    
    % sets the position callback function
    hAPI = iptgetapi(hObj);
    fcnC = makeConstrainToRectFcn(tStr,xLim,yLim);
    hAPI.setPositionConstraintFcn(fcnC);
    
else
    % case is the new format objects

    % sets the object drawing area
    xyLim = [xLim(1),yLim(1),diff(xLim),diff(yLim)];
    set(hObj,'DrawingArea',xyLim);        
end