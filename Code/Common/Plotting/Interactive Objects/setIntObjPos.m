function setIntObjPos(hObj,pPos,isOld,runListner)

% sets the default input argument
if ~exist('isOld','var'); isOld = isOldIntObjVer(); end
if ~exist('runListner','var'); runListner = true; end

% updates the object position based on the type
if isOld
    % case is the old version objects
    
    % resets the api position
    hAPI = iptgetapi(hObj);
    hAPI.setPosition(pPos);
    
else
    % case is the new version objects
    
    % resets the objects position
    if isa(hObj,'images.roi.Ellipse')
        % case is the object is an ellipse        
        pAx = pPos(3:4)/2;
        pC = pPos(1:2) + pAx;
        set(hObj,'SemiAxes',pAx,'Center',pC)
        
    else
        % case is the other object types
        set(hObj,'Position',pPos);
    end
    
    % retrieves the listener functions for the interactive object
    if runListner
        try
            hList = hObj.AutoListeners__;
            evntName = cellfun(@(x)(x.EventName),hList,'un',0);
            isMove = strcmp(evntName,'MovingROI');

            % runs the ROI movement callback function
            cbFcn = hList{isMove}.Callback;
            feval(cbFcn,hObj,pPos);
        end
    end
end