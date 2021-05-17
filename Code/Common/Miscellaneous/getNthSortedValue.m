% --- retrieves the n-th sorted value from the array, I
function p = getNthSortedValue(I,N)

if isempty(I)
    p = 0;
else                        
    Is = sort(I(:),'descend');
    p = Is(min(numel(I),N));
end