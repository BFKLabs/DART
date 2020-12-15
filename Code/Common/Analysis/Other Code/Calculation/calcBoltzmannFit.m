% --- calculates the linear fits for all the x/y data values --- %
function [fitR,Yfit,CIk] = calcBoltzmannFit(X,Y,isOffset)

% memory allocation
pLevel = 0.95;
if (nargin < 3); isOffset = false; end

% sets the initial parameter values
[~,imn] = min(abs(1/2-Y));
[EC50_0,k_0,Y_0,Y_A] = deal(X(imn),1,min(Y),1);

% calculates the linear fit, and calculates the gradient confidence
% intervals and fit coefficients
if (isOffset)
    % normalises that value
    Y_A = Y(1) - min(Y);
    Y = (Y - Y_0)/Y_A;
else
    % sets the offset to zero
    Y_0 = 0;
end

% sets the fit function (a linear line that passes through the origin)
g = fittype(@(k,EC50,x) 1./(1 + exp(k*(x - EC50))));
fitR0 = fit(X,Y,g,'StartPoint',[k_0 EC50_0]);
CI = confint(fitR0,pLevel);  

% sets the fitted values
CIk = diff(CI(:,2),1)/2;
Yfit = Y_A./(1 + exp(fitR0.k*(X - fitR0.EC50))) + Y_0;    

% sets the total fit struct
fitR = struct('Y_A',Y_A,'Y_0',Y_0,'k',fitR0.k,'EC50',fitR0.EC50);