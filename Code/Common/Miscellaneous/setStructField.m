% --- retrieves the sub-field, pStr, from the struct, p
function p = setStructField(p,pStr,pVal)

% ensures the field name/values are stored in cell arrays
if ~iscell(pStr)
    [pStr,pVal] = deal({pStr},{pVal});
end

% evaluates all the struct fields
for i = 1:length(pStr)
    eval(sprintf('p.%s = pVal{i};',pStr{i}));
end