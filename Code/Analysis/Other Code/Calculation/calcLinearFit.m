% --- calculates the linear fits for all the x/y data values --- %
function [M,CI,R2] = calcLinearFit(Xnw,Ynw)

% initialisations
pLevel = 0.95;
ii = ~isnan(Xnw) & ~isnan(Ynw);

% sets the fit function (a linear line that passes through the origin)
g = fittype(@(M,x) M*x);
   
% calculates the linear fit, and calculates the gradient confidence
% intervals and fit coefficients
fitR = fit(Xnw(ii),Ynw(ii),g,'StartPoint',1); 
[M,CI] = deal(fitR.M,confint(fitR,pLevel)');    
R2 = corr(Ynw(ii),M*Xnw(ii));

% sets the output argument as a struct (if only one output)
if (nargout == 1)
    A = struct('M',M,'CI',CI,'R2',R2);
    M = A;
end
