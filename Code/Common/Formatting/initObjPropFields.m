% --- adds empty fields for the list of fields
function varargout = initObjPropFields(hObj,pFldStr)

% adds empty fields for each of the input arguments
for i = 1:length(pFldStr)
    hObj = addObjProp(hObj,pFldStr{i});
end

% returns the object (if required)
if nargout == 1
    varargout{1} = hObj;
end