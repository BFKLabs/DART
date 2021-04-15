% --- creates a subplot axes
function hAx = createSubPlotAxes(hP,dim,ind)

% sets the default input arguments
if (nargin < 1); hP = get(gca,'Parent'); end
if (nargin < 2); dim = [1 1]; end
if (nargin < 3); ind = 1; end

% deletes any existing axes (first axes only)
if (ind == 1); delete(gca); end

% creates the axis
hAx = axes('OuterPosition',calcOuterPos(dim(1),dim(2),ind),'Parent',hP);        

% sets the userdata properties and holds on to the figure
set(hAx,'UserData',ind);
hold(hAx,'on');