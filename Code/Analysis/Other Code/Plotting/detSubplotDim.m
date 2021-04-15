% --- determines the most efficient subplot dimensions, given nSub plots
function [nRow,nCol] = detSubplotDim(nSub)

% calculates the simplest subplot dimensions
[nCol,nRow] = deal(ceil(0.5*(1+sqrt(1+4*nSub)))-1,ceil(sqrt(nSub)));