% --- resets the width of a vertically orientated legend
function lgP = resetVertLegendWidth(hLg,lgP)

% retrieves the legend position (if not provided)
if (nargin == 1); lgP = get(hLg,'position'); end
