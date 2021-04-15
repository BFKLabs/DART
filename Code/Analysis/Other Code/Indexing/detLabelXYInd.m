% --- determines the subplots that contains the x/y-labels
function [ixInd,iyInd] = detLabelXYInd(nApp,nCol)

% if the column index is empty, then the graph is being combined into a
% single figure. if so, then use a single apparatus/column count
if (isempty(nCol)); [nApp,nCol] = deal(1); end

% initialisations
nRow = ceil(nApp/nCol);
if (mod(nRow,2) == 1)
    iyInd = floor(nRow/2)*nCol + 1;    
else
    iyInd = nRow/2 + 0.5;
end

% initialisations
if (mod(nCol,2) == 1)
    ixInd = (nRow-1)*nCol + (floor(nCol/2)+1);    
else
    ixInd = nCol/2 + 0.5;
end




