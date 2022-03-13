% --- retrieves the final GUI resized position
function fPos = getFinalResizePos(hObject,Wmin,Hmin)

% global variables
del = 60;
scrSz = get(0,'MonitorPositions');

% detects when the figure resize has finished
fPos = detectResizeFinish(hObject);

% ensures the figure is within the required dimensions
if nargin > 1
    fPos(3) = roundP(max(Wmin,fPos(3)));
    fPos(4) = roundP(max(Hmin,fPos(4)));
end
   
% sets the left/bottom location of the figure
fPos(1) = max(1,min(scrSz(3)-fPos(3)-del,fPos(1)));
fPos(2) = max(1,min(scrSz(4)-fPos(4)-del,fPos(2)));

% resets the position of the figure
set(hObject,'position',fPos); 
% set(setObjVisibility(hObject,'off'),'position',fPos); 
pause(0.1);