% --- centres the figure position to the screen's centre
function resetFigPosition(hFig)

% global variables
scrSz = getPanelPosPix(0,'Pixels','ScreenSize');

% retrieves the screen and figure position
hPos = get(hFig,'position');

% resets the left position of the figure (if too close to the right edge)
if sum(hPos([1,3])) > scrSz(3)
    hPos(1) = scrSz(3)-hPos(3);
end
    
% resets the bottom position of the figure (if too close to the top edge)
if sum(hPos([2,4])) > scrSz(4)
    hPos(2) = scrSz(4)-hPos(4);
end
    
% resets the figure position
set(hFig,'position',hPos)