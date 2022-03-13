% --- optimises the parameters for the distribution given by, dType
function [pPara,pOut] = optDistributionPara(Y,N,dType)

% sets the input parameters
if ~exist('N','var'); N = 101; end
if ~exist('dType','var'); dType = 'normal'; end

% other parameters
xLim = [min(Y),max(Y)];
opt = optimset('display','none');

% calculates the search direction vector
if mean(Y) < mean(xLim)
    iMx = [2,1];
else
    iMx = [1,2];
end
   
% optimises the distribution in the forward/reverse directions
for i = iMx
    xLim(i) = fminbnd(@optFunc,xLim(1),xLim(2),opt,Y,N,i,xLim,dType);
end

% returns the final parameter/signal estimation struct
[~,pPara,pOut] = optFunc(xLim(1),Y,N,1,xLim,dType);

% --- calculates the optimisation objective function
function [F,pMLE,pOut] = optFunc(xNw,Y,N,iMx,x,dType)

% parameters
nMin = 5;

% calculates the distribution parameter estimate
x(iMx) = xNw;
ii = (Y >= x(1)) & (Y <= x(2));

if sum(ii) < nMin
    F = 1e6;
    return
else
    pMLE = mle(Y(ii),'distribution',dType);
end

% calculates te 
[Nc,Xedge] = histcounts(Y,N);

% calculates the mle/pdf estimates
xi = 0.5*(Xedge(1:end-1) + Xedge(2:end));
Ypdf = Nc/(length(Y)*diff(xi([1,2])));

% calculates the distribution pdf 
switch dType
    case 'normal'
        Yest = normpdf(xi,pMLE(1),pMLE(2));
    case 'ev'
        Yest = evpdf(xi,pMLE(1),pMLE(2));
end

% calculates the object function value
F = sum((Nc/sum(Nc)).*(Ypdf - Yest).^2);

% sets the output data struct (if required)
if nargout > 1
    pOut = struct('xi',xi,'Yest',Yest,'Ypdf',Ypdf);
end