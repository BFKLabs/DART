% --- retrieves the sub-region image stack estimate from the image, I
function [IR,IC] = getSubRegionStackEst(I)

% parameters
del = 25;
szB = 100;
sz = size(I);

% determines the sub-image block count and row/column offset
nB = floor((sz-szB)/del);
pOfs = ceil((sz-(nB*del+szB))/2);

% retrieves the block row/column indices
iRB = arrayfun(@(x)((pOfs(1)+(x-1)*del)+(1:szB)),1:nB(1),'un',0);
iCB = arrayfun(@(x)((pOfs(2)+(x-1)*del)+(1:szB)),1:nB(2),'un',0);

% sets the row/column image blocks 
IR = cellfun(@(x)(nonZeroMean(I(x,:))),iRB,'un',0);
IC = cellfun(@(x)(nonZeroMean(I(:,x)')),iCB,'un',0);


% --- calculates the non-zero mean signals from Y
function Ymn = nonZeroMean(Y)

% memory allocation
Ymn = zeros(1,size(Y,2));

% determines if there are any non-zero values
ii = abs(Y)>0;
if any(ii(:))
    jj = any(ii,1);
    Ymn(jj) = cellfun(@(x,y)...
                    (mean(x(y))),num2cell(Y(:,jj),1),num2cell(ii(:,jj),1));
end