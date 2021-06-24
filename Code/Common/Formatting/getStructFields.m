% --- retrieves the values from the struct 
function Y = getStructFields(p,pStr,isNum)

% retrieves the struct field names (if not provided)
if nargin < 2
    pStr = fieldnames(p);
elseif isempty(pStr)
    pStr = fieldnames(p);
end

% removes any optogenetics fields
pStr = pStr(~strcmp(pStr,'pOpto'));
if nargin < 3; isNum = false; end

% evaluates each of the fields
Y = cell(length(pStr),1);
for i = 1:length(pStr)
    Y{i} = eval(sprintf('p.%s',pStr{i}));
end

% converts the array to numerical array
if isNum; Y = cell2mat(Y); end