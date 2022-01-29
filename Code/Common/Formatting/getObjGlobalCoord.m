function pPos = getObjGlobalCoord(hObj)

% retrieves the current object positional vector
pPos = get(hObj,'Position');

% keep looping until the parent object it the figure handle
while 1
    % retrieves the current object parent handle
    hObjP = get(hObj,'Parent');
    if isa(hObjP,'matlab.ui.Figure')
        % if the parent is a figure, then exit the loop
        break
    else
        % ensures the object units are in pixels
        hUnits0 = get(hObjP,'Units');
        set(hObjP,'Units','Pixels')
        
        % otherwise, append the left/bottom position to the total
        pPosNw = get(hObjP,'Position');
        pPos(1:2) = pPos(1:2) + pPosNw(1:2);
        
        % resets the object handle and units
        hObj = hObjP;
        set(hObjP,'Units',hUnits0)
    end
end