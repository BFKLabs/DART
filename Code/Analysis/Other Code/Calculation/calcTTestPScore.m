% --- calculates the pair-wise 2-tailed t-test p-scores --- %
function [p,T,pStr] = calcTTestPScore(Y,SE)

% ensures the proportions/sample size arrays are vectors
pLvl = [log10(0.05) -2 -3 -5 -10 -20 -50 -inf];
[Y,SE] = deal(Y(:),SE(:));

% memory allocation
n = length(Y);
[T,pStr] = deal(NaN(n),repmat({'N/S'},n));

% calculates the 
for i = 1:n
    for j = 1:n
        if (i ~= j)                                    
            % calculates the z-score
            se = sqrt(SE(i)^2 + SE(j)^2);            
            T(i,j) = (Y(i)-Y(j))/se;
        end
    end
end

% calculates the probabilities
p = 2*normcdf(-abs(T));
pL = log10(p); 

% sets the p-level significant strings
for i = 1:length(pLvl)-1
    % determines the elements which are at the current significance level
    ii = (pL <= pLvl(i)) & (pL >= pLvl(i+1));
    
    % sets the p-level signficance strings
    switch (i)
        case(1)
            pStr(ii) = {'0.05'}; 
        case(2)
            pStr(ii) = {'0.01'}; 
        case(3)
            pStr(ii) = {'0.001'}; 
        otherwise
            pStr(ii) = {sprintf('10^(%i)',pLvl(i))}; 
    end
end

% sets the output string to the significance strings (if only one output)
if (nargout == 1); p = pStr; end