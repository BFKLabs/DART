function setIntObjResizeState(hObj,State,isOld)

% sets the default input argument
if ~exist('isOld','var'); isOld = isOldIntObjVer(); end

% updates the resize/interaction flag based on flag type
if isOld
    % case is an older format interactive object
    hAPI = iptgetapi(hObj);
    hAPI.setResizable(State);
    
else
    % case is a newer format interactive object
    if State
        set(hObj,'InteractionsAllowed','all');                    
    else
        set(hObj,'InteractionsAllowed','translate');
    end
end
    