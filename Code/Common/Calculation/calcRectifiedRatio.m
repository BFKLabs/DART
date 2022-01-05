function Rxy = calcRectifiedRatio(X,Y)

if abs(X) > abs(Y)
    Rxy = Y/X;
else
    Rxy = X/Y;
end