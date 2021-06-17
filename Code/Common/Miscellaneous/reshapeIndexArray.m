% --- reshapes the index array, iGrp0, to the array of size szGrp
function iGrp = reshapeIndexArray(iGrp0,szGrp)

% memory allocation
iGrp = zeros(szGrp);

% sets the index array values
for i = 1:length(iGrp0)
    % calculates the region row/column index
    iCol = mod(i-1,szGrp(2))+1;
    iRow = floor((i-1)/szGrp(2))+1;
    
    % sets the values into the array
    iGrp(iRow,iCol) = iGrp0(i);
end