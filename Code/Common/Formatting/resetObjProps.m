% --- resets the objects (from hParent) that have the property field, pStr
%     with the property value, pVal
function resetObjProps(hParent,pStr,pVal)

% determines objects (from the parent object) that have the property, pStr
hObj = findall(hParent); 
hasProp = arrayfun(@(x)(isprop(x,pStr)),hObj); 

% updates the object property values
arrayfun(@(x)(set(x,pStr',pVal)),hObj(hasProp))