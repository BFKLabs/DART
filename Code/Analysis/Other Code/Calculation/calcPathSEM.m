% --- calculates the path SEM boundary
function pSEM = calcPathSEM(pMn,pSEM0,nG)

% initialisations & memory allocation
xi0 = 1:size(pMn,1); 
[xi,phi] = deal(linspace(xi0(1),xi0(end),100*size(pMn,1)+1),linspace(0,2*pi,250)); 
[xS,yS] = deal(zeros(length(phi),length(xi))); 

% calculates the inerpolated mean/SEM path values
[xMnI,yMnI] = deal(interp1(xi0,pMn(:,1),xi),interp1(xi0,pMn(:,2),xi));
[xSEMI,ySEMI] = deal(interp1(xi0,pSEM0(:,1),xi),interp1(xi0,pSEM0(:,2),xi));

% calculates the interpolated circles along the path
[dX,dY] = deal(cos(phi),sin(phi)); 
for i = 1:length(xi)
    [xS(:,i),yS(:,i)] = deal(xMnI(i)+xSEMI(i)*dX,yMnI(i)+ySEMI(i)*dY); 
end

% calculates the binary mask of the interpolated regions
[xS,yS] = deal(roundP(xS(:)),roundP(yS(:))); 
ii = sqrt((xS-nG/2).^2 + (yS-nG/2).^2) <= nG/2;
ind = sub2ind(nG*[1 1],yS(ii),xS(ii));
B = reshape(hist(ind,1:(nG^2)),nG*[1 1]) > 0;

% calculates the SEM boundary from the binary region 
pB = bwboundaries(B);
pSEM = [smooth(pB{1}([1:end,1],2)),smooth(pB{1}([1:end,1],1))];