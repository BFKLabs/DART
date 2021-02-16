% --- retrieves the sub-field, pStr, from the struct, p
function p = setStructField(p,pStr,pVal)

eval(sprintf('p.%s = pVal;',pStr));