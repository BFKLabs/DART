% --- creates a loadbar using the ProgressDialog function
function h = ProgressLoadbar(wStr)

% retrieves the current figure
hFig = get(groot,'CurrentFigure');

% creates the loadbar
h = ProgressDialog('StatusMessage',wStr,'Indeterminate',true);

% resets the current figure
if ~isempty(hFig) && isvalid(hFig)
    set(0,'CurrentFigure',hFig); 
end