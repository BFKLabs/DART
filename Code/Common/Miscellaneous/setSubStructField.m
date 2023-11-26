% sets the sub-struct fields, pStr, 
function p = setSubStructField(p,pStr,pVal)

% initialsiations
evStr = 'p';
if ~iscell(pStr); pStr = {pStr}; end

% sets up the evaludation string
for i = 1:length(pStr)
    evStr = sprintf('%s.%s',evStr,pStr{i});
end

% evaluates the update string
eval(sprintf('%s = pVal;',evStr))