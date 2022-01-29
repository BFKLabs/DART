% --- determines the axes objects the mouse is currently hovering over
function hHover = findAxesHoverObjects(hFig,mStr,hP)

% retrieves the current axes handle


% sets the parent object (if not provided)
if exist('hP','var')
    %
    try
        mPos = get(hP,'CurrentPoint');
    catch
        mPos = get(hFig,'CurrentPoint');
    end
else
    %
    hAx = get(hFig,'CurrentAxes');
    [mPos,hP] = deal(get(hAx,'CurrentPoint'),hAx);
end

%
if ~exist('mStr','var')
    mStr = {'type','patch';'tag','hSigBlk';'tag','hBlkPrompt'};
end

% finds the objects from the current axes
axObj = cell(size(mStr,1),1);
for i = 1:size(mStr,1)
    axObj{i} = findobj(hP,mStr{i,1},mStr{i,2});
end

% converts the cell array to a numeric array
axObj = cell2cell(axObj);

% determines the objects that the mouse is currently hovering over
isHover = false(length(axObj),1);
for i = 1:length(isHover)
    % ensures the units are in terms of pixels
    hUnit0 = get(axObj(i),'Units');
    set(axObj(i),'Units','Pixels');
    
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
            
        case {'uipanel','uicontrol'}
            pPos = getObjGlobalCoord(axObj(i));
            [xD,yD] = deal(pPos(1)+[0,pPos(3)],pPos(2)+[0,pPos(4)]);
            
            isHover(i) = (prod(sign(xD-mPos(1,1))) == -1) && ...
                         (prod(sign(yD-mPos(1,2))) == -1);            
            
        case 'line'  
            pP = get(hP,'Position');
            [xL,yL] = deal(get(hP,'xlim'),get(hP,'ylim'));
            [dxL,dyL] = deal(diff(xL),diff(yL));
            
            xD = pP(3)*(get(axObj(i),'xData')-xL(1))/dxL;
            yD = pP(4)*(get(axObj(i),'yData')-yL(1))/dyL;            
            mP = pP(3:4).*(mPos(1,1:2)-[xL(1),yL(1)])./[dxL,dyL];
            
            isHover(i) = any(pdist2([xD(:),yD(:)],mP) < 5);
    end
    
    % resets the original object units
    set(axObj(i),'Units',hUnit0);    
end

% returns the objects which are being hovered over
hHover = axObj(isHover);
