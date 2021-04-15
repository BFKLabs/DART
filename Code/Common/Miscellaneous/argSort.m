% --- determines the sorted indices
function iSort = argSort(y,isDescend)

% sets the default input argument
if nargin < 2; isDescend = false; end

% sort the values dependent on the direction
if isDescend
    % case is sorting in descending order
    [~,iSort] = sort(y,'descend');
else
    % case is sorting in ascending order
    [~,iSort] = sort(y);
end