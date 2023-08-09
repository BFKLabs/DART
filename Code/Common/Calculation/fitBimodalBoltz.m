function [pExp,Yfit] = fitBimodalBoltz(x,y)

%
[x,y] = deal(x(:),y(:));
[Ymx,Xmx] = deal(max(y),max(x));

% 
fStr = 'A/((1+exp(k1*(x-xH1)))*(1+exp(k2*(x-xH2))))';
g = fittype(fStr,'coeff',{'A','k1','xH1','k2','xH2'});

%
x0 = [0.8*Ymx,  -1.0, 0.1*Xmx,  1.0, 0.9*Xmx];
xL = [0.5*Ymx, -10.0,       0,  0.1, 0.5*Xmx];
xU = [1.5*Ymx,  -0.1, 0.5*Xmx, 10.0,     Xmx];
    
% sets the fit options struct
fOpt = fitoptions('method','NonlinearLeastSquares','Lower',xL,...
                  'Upper',xU,'StartPoint',x0,'MaxFunEvals',1e10,...
                  'MaxIter',1e10);
              
% calculates the fitted values
pExp = fit(x,y,g,fOpt);
Yfit = calcFittedValues(g,pExp,x);