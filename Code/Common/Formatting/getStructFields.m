% --- retrieves the values from the struct 
function Y = getStructFields(p,pStr,isNum)

% retrieves the struct field names (if not provided)
if (nargin < 2)
    pStr = fieldnames(p);
elseif (isempty(pStr))
    pStr = fieldnames(p);
end

% 
pStr = pStr(~strcmp(pStr,'pOpto'));
if (nargin < 3); isNum = false; end

% retrieves the values based on the matlab release
if (verLessThan('matlab','8.4'))
    % case is for R2014a and earlier 
    Y = cellfun(@(x)(eval(sprintf('p.%s',x))),pStr,'un',0);
else
    % case is for R2014b and later    
    
    % evaluates each of the fields
    Y = cell(length(pStr),1);
    for i = 1:length(pStr)
        Y{i} = eval(sprintf('p.%s',pStr{i}));
    end
end

% converts the array to numerical array
if (isNum); Y = cell2mat(Y); end