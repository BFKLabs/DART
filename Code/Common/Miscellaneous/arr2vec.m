% --- converts an array to a vector
function v = arr2vec(A,isRow)

% sets the input variables
if ~exist('isRow','var'); isRow = false; end

% converts the array to a column vector
v = A(:);
if isRow; v = v'; end