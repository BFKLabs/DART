function Rxy = calcRectifiedRatio(X,Y)

%
Rxy = arrayfun(@(x,y)(calcRectifiedRatioFcn(x,y)),X,Y);

% --- calculates the individual value rectified ratio
function Rxy = calcRectifiedRatioFcn(X,Y)

if abs(X) < abs(Y)
    Rxy = Y/X;
else
    Rxy = X/Y;
end