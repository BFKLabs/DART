% --- opens a figure created by a class object
function openClassFigure(hFig,isVis)

% sets the default input arguments
if ~exist('isVis','var'); isVis = true; end

% centers the figure and makes it visible
centerfig(hFig);
refresh(hFig);

% makes the figure visible (if required)
if isVis
    set(hFig,'Visible','on');
end

% redraws the figure
drawnow
pause(0.05);