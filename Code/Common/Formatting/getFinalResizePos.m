% --- retrieves the final GUI resized position
function fPos = getFinalResizePos(hObject,Wmin,Hmin)

% detects when the figure resize has finished
yGap = 60;
scrSz = get(0,'Screensize');
fPos = detectResizeFinish(hObject);

% ensures the figure is within the required dimensions
if nargin > 1
    fPos(3) = roundP(max(Wmin,fPos(3)));
    fPos(4) = roundP(max(Hmin,fPos(4)));
end

% resets the left location
fPos(1) = min(max(1,fPos(1)),scrSz(3)-fPos(3));
fPos(2) = min(max(1,fPos(2)),scrSz(4)-(fPos(4)+yGap));

% resets the position of the figure
set(hObject,'position',fPos); 
% set(setObjVisibility(hObject,'off'),'position',fPos); 
pause(0.1);