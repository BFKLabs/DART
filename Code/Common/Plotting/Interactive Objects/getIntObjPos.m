function pPos = getIntObjPos(hObj,isOld)

% sets the default input argument
if ~exist('isOld','var'); isOld = isOldIntObjVer(); end

% updates the object position based on the type
if isOld
    % case is the old version objects
    
    % resets the api position
    hAPI = iptgetapi(hObj);
    pPos = hAPI.getPosition();
    
else
    % case is the new version objects
    
    % resets the objects position
    if isa(hObj,'images.roi.Ellipse')
        % case is the object is an ellipse  
        pC = get(hObj,'Center');
        pAx = get(hObj,'SemiAxes');
        pPos = [(pC-pAx),2*pAx];
        
    else
        % case is the other object types
        pPos = get(hObj,'Position');
    end
end