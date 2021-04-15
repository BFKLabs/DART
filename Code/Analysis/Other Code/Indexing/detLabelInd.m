% --- 
function [ixLbl,iyLbl,iyLbl2] = detLabelInd(nApp,nCol)

% if the column index is empty, then the graph is being combined into a
% single figure. if so, then use a single apparatus/column count
if (isempty(nCol)); [nApp,nCol] = deal(1); end

% initialisations
xi = 1:nApp;
xiM = mod(xi-1,nCol) + 1;

% determines the column groupings
iGrp = cellfun(@(x)(find(xiM == x)),num2cell(1:nCol),'un',0);
jGrp = find(xiM == nCol);

% determines the sub-plots to have y-labels
[iyLbl,iyLbl2] = deal(iGrp{1},jGrp);
if (mod(nApp,nCol) ~= 0); iyLbl2 = [iyLbl2,nApp]; end

% determines the sub-plots to have x-labels
ixLbl = zeros(1,nCol);
for i = 1:nCol
    [~,imx] = max(xi(iGrp{i}));
    ixLbl(i) = iGrp{i}(imx);
end





