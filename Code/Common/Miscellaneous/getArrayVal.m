% --- returns the ind-th element of the array, X
function Y = getArrayVal(X,ind)

if exist('ind','var')
    % case is the array index was provided
    if iscell(X)
        % array is a cell array
        Y = X{ind};
    else
        % array in a non-cell array
        Y = X(ind);
    end
else
    % case is the array index wasn't provided (use the last element)
    if iscell(X)
        % array in a cell array
        Y = X{end};
    else
        % array in a non-cell array
        Y = X(end);
    end
end