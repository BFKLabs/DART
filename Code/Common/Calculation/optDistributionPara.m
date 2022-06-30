% --- optimises the parameters for the distribution given by, dType
function [pPara,pOut] = optDistributionPara(Y,dType)

% sets the input parameters
if ~exist('dType','var'); dType = 'normal'; end
% opt = optimset('display','iter');

% returns the final parameter/signal estimation struct
[xLim,N0] = setupSolverPara(Y);
N = ceil(N0*mean(max(Y)/mean(xLim)));
[~,pPara,pOut] = optFunc(xLim(1),Y,N,1,xLim,dType);

% --- determines the solver parameters (histogram discretisation and search
%     domain limits
function [xLim,NH] = setupSolverPara(Y0)

% parameters
Nmin = 20;
rTol = 1/3;

% determines a rough estimate of the location of the first histogram peak
[N0,xi0] = histcounts(Y0,'BinMethod','fd');
if length(N0) < Nmin
    [N0,xi0] = histcounts(Y0,Nmin);
end

% calculates the bin mid-points
xiH = xi0(1:end-1) + diff(xi0(1:2))/2;
    
% determines the largest histogram count grouping
iGrp = getGroupIndex(N0);
NGrp = cellfun(@(x)(sum(N0(x))),iGrp);

% determines the first major peak
iMx = find(NGrp/max(NGrp) > rTol,1,'first');
jGrp = iGrp{iMx};
[N0,xiH] = deal(N0(jGrp),xiH(jGrp));

% sets the approximate 
xLim = xiH(argMax(N0))*[1,3]/2;
Y = Y0((Y0 >= xLim(1)) & (Y0 <= xLim(2)));

% calculates the estimated 
[Yiqr,nY] = deal(iqr(Y),length(Y));
H = 2*Yiqr*(nY^(-1/3));
NH = max(10,ceil(range(Y)/H));

% --- calculates the optimisation objective function
function [F,pMLE,pOut] = optFunc(xNw,Y,N,iMx,x,dType)

% parameters
nMin = 5;

% calculates the distribution parameter estimate
x(iMx) = xNw;
ii = (Y >= x(1)) & (Y <= x(2));

if sum(ii) < nMin
    F = 1e6;
    if nargout > 1
        [pMLE,pOut] = deal([]);
    end
        
    return
else
    pMLE = mle(Y(ii),'distribution',dType);
end

% calculates the histogram counts
xiH = linspace(0,max(Y),N+1);
[Nc,Xedge] = histcounts(Y,xiH);

% calculates the mle/pdf estimates
xi = 0.5*(Xedge(1:end-1) + Xedge(2:end));
Ypdf = Nc/(sum(ii)*diff(xi([1,2])));

% calculates the distribution pdf 
switch dType
    case 'normal'
        Yest = normpdf(xi,pMLE(1),pMLE(2));
    case 'lognormal'
        Yest = lognpdf(xi,pMLE(1),pMLE(2));        
    case 'weibull'
        Yest = wblpdf(xi,pMLE(1),pMLE(2));           
    case 'ev'
        Yest = evpdf(xi,pMLE(1),pMLE(2));        
end

% calculates the object function value
F = sum((Nc/sum(Nc)).*(Ypdf - Yest).^2);

% sets the output data struct (if required)
if nargout > 1
    pOut = struct('xi',xi,'Yest',Yest,'Ypdf',Ypdf);
end