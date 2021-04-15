% --- gets the field, fldStr, from the struct p
function fldVal = getFieldValue(p,fldStr)

% sets up the parameter string
fldVal = eval(getFieldStr('p',fldStr));
