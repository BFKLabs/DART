% --- determines the axes objects the mouse is currently hovering over
function hHover = findAxesHoverObjects(hFig)

% retrieves the current axes handle
hAx = get(hFig,'CurrentAxes');
mPos = get(hAx,'CurrentPoint');

% finds the objects from the current axes
axObj = [findobj(hAx,'type','patch');...
         findobj(hAx,'tag','hSigBlk');...
         findobj(hAx,'tag','hBlkPrompt')];
isHover = false(length(axObj),1);

% determines the objects that the mouse is currently hovering over
for i = 1:length(isHover)
    switch get(axObj(i),'Type')
        case 'patch'
            [xD,yD] = deal(get(axObj(i),'xData'),get(axObj(i),'yData'));
            isHover(i) = (prod(sign(xD(2:3)-mPos(1,1))) == -1) && ...
                (prod(sign(yD(1:2)-mPos(1,2))) == -1);
            
        case 'hggroup'
            hP = findobj(axObj(i),'type','patch');
            [xD0,yD0] = deal(get(hP,'xData'),get(hP,'yData'));
            [xD,yD] = deal([min(xD0),max(xD0)],[min(yD0),max(yD0)]);
            
            isHover(i) = (prod(sign(xD-mPos(1,1))) == -1) && ...
                (prod(sign(yD-mPos(1,2))) == -1);
            
    end
end

% returns the objects which are being hovered over
hHover = axObj(isHover);