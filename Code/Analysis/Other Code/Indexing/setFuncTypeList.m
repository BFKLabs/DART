% --- sets the function type list values
function fType = setFuncTypeList(pData)

if isempty(pData)
    fType = [];
else
    fType = combineNumericCells(field2cell(pData,'fType'))';
    fType(isnan(fType)) = 0;        
end