function Y = colMult(Y,iCol,dY)

if ~isempty(Y)
    Y(:,iCol) = Y(:,iCol)*dY;
end