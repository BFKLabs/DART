% --- calculates a default uitable height
function H = calcTableHeight(nRow,Hofs,hasRH)

% global variables
global H0T HWT

% sets the 2nd offset to zero (if not already set)
if (nargin < 2); Hofs = 0; end
if (nargin < 3); hasRH = true; end

% calculates the height
H = H0T + (HWT-(~hasRH))*nRow + Hofs;