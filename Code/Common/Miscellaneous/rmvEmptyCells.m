% --- remove any empty elements from the cell array A
function A = rmvEmptyCells(A)

A = A(~cellfun(@isempty,A));