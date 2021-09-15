% --- creates a subplot axes
function hAx = createSubPlotAxes(hP,dim,ind)

% sets the default input arguments
if (nargin < 1); hP = getCurrentAxesProp('Parent'); end
if (nargin < 2); dim = [1 1]; end
if (nargin < 3); ind = 1; end

% deletes any existing axes (first axes only)
if (ind == 1)
    hAx0 = findall(hP,'type','Axes');
    if ~isempty(hAx0); delete(hAx0); end
end

% creates the axis
hAx = axes('OuterPosition',calcOuterPos(dim(1),dim(2),ind));        

% sets the userdata properties and holds on to the figure
set(hAx,'Parent',hP,'UserData',ind);
hold(hAx,'on');