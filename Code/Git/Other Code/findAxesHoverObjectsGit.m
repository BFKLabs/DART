% --- determines the axes objects the mouse is currently hovering over
function hHover = findAxesHoverObjectsGit(hFig,mStr,hP,dX)

% retrieves the current axes handle
if ~exist('dX','var'); dX = 0; end

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
            pPos = getObjGlobalCoordGit(axObj(i)) + dX*[-1,-1,2,2];
            [xD,yD] = deal(pPos(1)+[0,pPos(3)],pPos(2)+[0,pPos(4)]);
            
            isHover(i) = (prod(sign(xD-mPos(1,1))) == -1) && ...
                         (prod(sign(yD-mPos(1,2))) == -1);            
            
    end
end

% returns the objects which are being hovered over
hHover = axObj(isHover);