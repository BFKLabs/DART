% --- function that calculates the endo/exocytosis curve fit parameters
function [Yfit,pF] = fitTimeConst(Y,Type,useOffset)

% turns off all warnings
wState = warning('off','all');

% sets the independent variable vector
X = (1:length(Y))';
optFit = optimset('display','none');

% sets the initial parameter values and function handle
switch (Type)
    case ('Endo') % case is for endocytosis
        x0 = [max(Y),0,1];
        optFcn = @(p,x)(p(1)-p(2))*exp(-p(3)*x) + p(2);        
    case ('Exo') % case is for exocytosis               
        x0 = [max(Y),1,X(find(Y>median(Y),1,'first'))];
        if (useOffset)
            x0([1 4]) = [x0(1),0] + min(Y)*[-1 1];
            optFcn = @(p,x)(p(1)-p(4))./(1+exp(-p(2)*(x-p(3))))+p(4);
        else
            optFcn = @(p,x)p(1)./(1+exp(-p(2)*(x-p(3))));
        end
end

% runs the optimisation solver
pF = lsqcurvefit(optFcn,x0,X,Y,[],[],optFit);

% calculates the optimal fit
Yfit = optFcn(pF,X);

% reverts the warnings back to their original state
warning(wState);