function Y = colAdd(Y,iCol,dY)

if ~isempty(Y)
    Y(:,iCol) = Y(:,iCol)+dY;
end