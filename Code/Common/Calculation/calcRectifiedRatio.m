function Rxy = calcRectifiedRatio(X,Y)

if X > Y
    Rxy = Y/X;
else
    Rxy = X/Y;
end