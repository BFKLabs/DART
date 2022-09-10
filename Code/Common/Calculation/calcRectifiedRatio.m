function Rxy = calcRectifiedRatio(X,Y)

%
[nX,nY] = deal(length(X),length(Y));

%
if nX*nY == 1
    Rxy = calcRectifiedRatioFcn(X,Y);
        
elseif nX == 1
    Rxy = arrayfun(@(y)(calcRectifiedRatioFcn(X,y)),Y);
    
elseif nY == 1    
    Rxy = arrayfun(@(x)(calcRectifiedRatioFcn(x,Y)),X);
    
elseif nX == nY
    Rxy = arrayfun(@(x,y)(calcRectifiedRatioFcn(x,y)),X,Y);
end

% --- calculates the individual value rectified ratio
function Rxy = calcRectifiedRatioFcn(X,Y)

if abs(X) < abs(Y)
    Rxy = Y/X;
else
    Rxy = X/Y;
end

% sets NaN/infinite ratio values to zero
if isinf(Rxy) || isnan(Rxy)
    Rxy = 0;
end