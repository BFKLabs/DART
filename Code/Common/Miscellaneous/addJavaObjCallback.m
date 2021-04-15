% --- adds the java object callback function
function addJavaObjCallback(jObj,cType,cFcn)

% retrieves the object callback properties handles
jObj_CB = handle(jObj,'CallbackProperties');

% sets the callback function properties
set(jObj_CB, cType, cFcn);