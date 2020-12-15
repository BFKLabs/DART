% --- calculates the pair-wise 2-tailed z-test p-scores --- %
function [p,Z,pStr] = calcPropPScore(P,N)

% ensures the proportions/sample size arrays are vectors
Nmin = 10;
pLvl = [log10(0.05) -2 -3 -5 -10 -20 -50 -inf];
[P,N] = deal(P(:),N(:));

% memory allocation
n = length(P);
[Z,pStr] = deal(NaN(n),repmat({'N/S'},n));

% calculates the 
for i = 1:n
    for j = 1:n
        if ((i ~= j) && (all(N([i j]) >= Nmin)))
            pp = (P(i)*N(i)+P(j)*N(j))/(N(i)+N(j));
            se = sqrt(pp*(1-pp)*((1/N(i))+(1/N(j))));
            
            % calculates the z-score
            Z(i,j) = (P(i)-P(j))/se;
        end
    end
end

% calculates the probabilities
p = 2*normcdf(-abs(Z));
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