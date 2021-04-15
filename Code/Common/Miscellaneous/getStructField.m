% --- retrieves the sub-field, pStr, from the struct, p
function pVal = getStructField(p,pStr,varargin)

pStrN = sprintf('p.%s',pStr);
for i = 1:length(varargin)
    pStrN = sprintf('%s.%s',pStrN,varargin{i});
end

pVal = eval(pStrN);