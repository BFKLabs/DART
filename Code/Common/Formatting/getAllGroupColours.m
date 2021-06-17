% --- retrieves the group colours
function pCol = getAllGroupColours(nCol,varargin)

% retrieves the distinguishable colour array
pCol = distinguishable_colors(nCol,'k');

% appends on the "None" colour row (if required)
if nargin == 1
    pCol = [0.81*ones(1,3);pCol];
end