% --- fits a bi-modal distribution to the data
function [p,Yfit] = fitTurnDirDist(X,Y,N)

% precalculations
ii = ~isnan(Y);

% offsets the angles by 90 degrees (so x > 0)
[x,y] = deal(reshape(X(ii),sum(ii),1),reshape(Y(ii),sum(ii),1));
N = reshape(N(ii),sum(ii),1); W = N./sum(N);

% sets the fit-type equation parameters
g = fittype('-sign(x)*A*abs(x/90)^n','coeff',{'n','A'});
        
% sets the initial value and the lower/upper bounds        
x0 = [ 1.00 0.90];
xL = [ 0.01 0.01];
xU = [10.00 1.00];   

% sets the fit options struct
fOpt = fitoptions('method','NonlinearLeastSquares','Lower',xL,...
                  'Upper',xU,'StartPoint',x0,'MaxFunEvals',1e10,...
                  'MaxIter',1e10,'Weight',W);
              
% runs the solver
[pExp,G] = fit(x,y,g,fOpt);   

% calculates the fitted values
Yfit = calcFittedValues(g,pExp,X);

% retrieves the coefficient values and confidence intervals
try
    pp = coeffvalues(pExp);
    ppS = diff(confint(pExp),[],1)/(2*1.96);    
catch
    [pp,ppS] = deal(NaN(1,2));
end

% sets the fitted values into the output data struct
[p,fStr] = deal(struct('R2',G.rsquare),fieldnames(pExp));
for i = 1:length(fStr)
    eval(sprintf('p.%s = zeros(1,2);',fStr{i}));
    eval(sprintf('p.%s(1) = pp(i);',fStr{i}));
    eval(sprintf('p.%s(2) = ppS(i);',fStr{i}));
end