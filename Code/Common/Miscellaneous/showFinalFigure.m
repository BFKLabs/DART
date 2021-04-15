% --- shows the final figure
function showFinalFigure(hFig)

% turns off all of the warnings
wState = warning('off','all');

% retrieves the figure position
fPos = get(hFig,'position');
               
% centres the figure and covers the figure with an edit box
hEdit = uicontrol('Style','edit','string','','position',...
                   [0 0 fPos(3:4)],'Parent',hFig);
pause(0.50);            

% makes the figure visible again
setObjVisibility(hFig,'on'); 
pause(0.20);              

% deletes the editbox
delete(hEdit)

% turns on the warnings again
warning(wState);