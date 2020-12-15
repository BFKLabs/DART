% --- sets up the struct field string
function pStr = getFieldStr(pStrBase,pStrSub)

% ensures the sub-fields are stored in a cell array
if ~iscell(pStrSub); pStrSub = {pStrSub}; end

% combines the sub-fields into the strings
pStr = pStrBase;
for i = 1:length(pStrSub)
    pStr = sprintf('%s.%s',pStr,pStrSub{i});
end