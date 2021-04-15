% --- retrieves the final GUI resized position
function fPos = getFinalResizePos(hObject,Wmin,Hmin)

% global variables
del = 60;
scrSz = get(0,'MonitorPositions');

% keep looping until the user has stopped moving the window
fPos0 = get(hObject,'position');
while (1)
    % pauses the update and retrieves the new figure position
    pause(0.2)
    fPos = get(hObject,'position');
    
    % check to see if the position arrays the same
    if (isequal(fPos,fPos0))
        % if so, then exit the loop
        break
    else
        % otherwise, reset the original positional array
        fPos0 = fPos;
    end
end

% ensures the figure is within the required dimensions
if (nargin > 1)
    fPos(3) = roundP(max(Wmin,fPos(3)));
    fPos(4) = roundP(max(Hmin,fPos(4)));
end
   
% sets the left/bottom location of the figure
fPos(1) = max(1,min(scrSz(3)-fPos(3)-del,fPos(1)));
fPos(2) = max(1,min(scrSz(4)-fPos(4)-del,fPos(2)));

% resets the position of the figure
set(setObjVisibility(hObject,'off'),'position',fPos); 
pause(0.1);