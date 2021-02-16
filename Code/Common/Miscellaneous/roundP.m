% --- rounds x to the nearest multiple of Prec
function y = roundP(x,Prec)

% if there is no precision value given, then use a default of 1
if (nargin == 1); Prec = 1; end

% calculates the rounder value
y = Prec*floor((x+(Prec/2))/Prec);