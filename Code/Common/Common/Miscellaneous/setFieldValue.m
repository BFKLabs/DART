% --- sets the value, fldVal, into the sub-field, fldStr of p
function p = setFieldValue(p,fldStr,fldVal)

% sets up the parameter string
pStr = getFieldStr('p',fldStr);
if ischar(fldVal)
    eval(sprintf('%s = %s;',pStr,fldVal));
else
    eval(sprintf('%s = fldVal;',pStr));
end

