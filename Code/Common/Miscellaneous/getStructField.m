% --- retrieves the field, pStr, from the struct, p
function pVal = getStructField(p,pStr,varargin)

% sets up the struct field string
pStrN = sprintf('p.%s',pStr);
for i = 1:length(varargin)
    pStrN = sprintf('%s.%s',pStrN,varargin{i});
end

% evaluates the struct field string
pVal = eval(pStrN);