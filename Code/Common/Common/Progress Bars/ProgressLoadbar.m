% --- creates a loadbar using the ProgressDialog function
function h = ProgressLoadbar(wStr,isHG1v)

% sets the default input arguments
if (nargin < 2); isHG1v = isHG1; end

% retrieves the current figure
if (isHG1v)
    hFig = get(0,'CurrentFigure');
else
    hFig = get(groot,'CurrentFigure');
end

% creates the loadbar
h = ProgressDialog('StatusMessage',wStr,'Indeterminate',true);

% resets the current figure
if (~isempty(hFig)); set(0,'CurrentFigure',hFig); end