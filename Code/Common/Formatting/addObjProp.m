function varargout = addObjProp(hObj,pFldStr,pVal)

try
    % attempts to add the field to the object
    addprop(hObj,pFldStr);
catch
    % if there was an error, then output a message to screen and exit
    eStr = sprintf('Unable to add field "%s" to object.',pFldStr);
    waitfor(msgbox(eStr,'Property Error','modal'))
    return
end

% if there is a default value, then set the field value 
if exist('pVal','var')
    set(hObj,pFldStr,pVal); 
end

% returns the 
if nargout == 1
    varargout{1} = hObj;
end