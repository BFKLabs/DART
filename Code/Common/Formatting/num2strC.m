% --- fast conversion of numbers to strings (returns a cell array)
function yStr = num2strC(y,prec,varargin)

% includes a carriage return in the precision string
[prec,sz] = deal([prec,'\n'],size(y));

% converts the cell array to a numerical array
if (iscell(y)); y = cell2mat(y(:)); end

% converts the numerical array to a string cell array
yStr = strsplit(sprintf(prec,y(:))).';
yStr = yStr(1:end-1);

% reshapes the array to match the original
if (nargin == 3); yStr = reshape(yStr,sz); end