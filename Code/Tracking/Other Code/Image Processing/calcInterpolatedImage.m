% --- calculates the interpolated image with the removed group, grpExc
function InwIntL = calcInterpolatedImage(Inw)

% calculates the 
[sz,IExc] = deal(size(Inw),isnan(Inw));
BD = ~bwmorph(IExc,'dilate',1);

% calculates the 
[yi,xi] = ind2sub(sz,find(BD)); 
try
    F = scatteredInterpolant(xi,yi,Inw(BD),'natural'); 
catch
    F = TriScatteredInterp(xi,yi,Inw(BD),'natural'); 
end

% calculates the interpolated image
[XX,YY] = meshgrid(1:sz(2),1:sz(1));
InwIntL = F(XX,YY);