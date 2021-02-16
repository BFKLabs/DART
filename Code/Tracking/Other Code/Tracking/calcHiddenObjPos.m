function [X,Y] = calcHiddenObjPos(ImgR,fP,dTol)

%
ImgR(isnan(ImgR)) = 0;

% determines the maxim
iMx = find(imregionalmax(ImgR));
[yMx,xMx] = ind2sub(size(ImgR),iMx);
DMx = sqrt((xMx-fP(1)).^2 + (yMx-fP(2)).^2);

% calculates the objective function (removes any points outside of the
% distance tolerance)
QMx = ImgR(iMx)./DMx;
if exist('dTol','var')
    QMx(DMx>dTol) = -1e10;
end

% determines the most    
iNw = argMax(QMx);
[X,Y] = deal(xMx(iNw),yMx(iNw));