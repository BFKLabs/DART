% --- calculates the final fitted values from the optimised parameters
function Yfit = calcFittedValues(g,pExp,X,Ysgn)

% sets the default input arguments
if (nargin == 3); Ysgn = 1; end

% initialisations
[a,gStr] = deal(coeffvalues(pExp),'g(');

% appends the coefficients to the the function string
for i = 1:length(a)
    gStr = sprintf('%s%f,',gStr,a(i));
end

% evaluates the string
Yfit = eval(sprintf('%sX);',gStr))*Ysgn;