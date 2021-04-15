% --- 
function hDim = getPlotObjTextHeight(hAx)

% memory allocation
hDim = struct('xAxH',0,'yAxW',0,'zAxH',0,'TH',0,'xLH',0,'yLH',0,'zLH',0);

% determines if there is a valid axes handle
if (isempty(hAx))
    % if no handle provided then exit
    return 
elseif (strcmp(get(hAx,'Visible'),'off'))
    % if the axes is invisible then exit
    return
end

% retrieves the axes position (in normalized units)
axPos = getPanelPosPix(hAx(1),'normalized','position');

% sets the z-label/axis height/widths (if there are 2 axis)
if (length(hAx) > 1)       
    % retrieves the z-label height (if it exists)
%     if (~isempty(hAx(2),'ylabel'))
%     if (~isempty(hLblY{2}))    
%         hDim.zLH = getPlotObjTextSize(hAx(2),hLblY{2},axPos,1);
%     end    
    
    % retrieves the z-axis width
    hDim.zAxH = getPlotObjTextSize(hAx(2),[],axPos,1);       
end

% sets the title height (if it exists)
hTitle = get(hAx(1),'Title');
if (~isempty(hTitle))    
    hDim.TH = getPlotObjTextSize(hAx(1),hTitle,axPos,2);
end

% sets the x-label height (if it exists)
hLblX = get(hAx(1),'xLabel');
if (~isempty(hLblX))    
    hDim.xLH = getPlotObjTextSize(hAx(1),hLblX,axPos,2);
end

% sets the y-label height (if it exists)
hLblY = get(hAx(1),'yLabel');
if (~isempty(hLblY))    
    hDim.yLH = getPlotObjTextSize(hAx(1),hLblY,axPos,1);
end

% sets the x axis label heights (if x-label not set)
if (hDim.xLH == 0)
    hDim.xAxH = getPlotObjTextSize(hAx(1),[],axPos,2);
end
    
% sets the y axis label heights (if y-label not set)
if (hDim.yLH == 0)
    hDim.yAxW = getPlotObjTextSize(hAx(1),[],axPos,1);
end

% --- 
function hDim = getPlotObjTextSize(hAx,hObj,axPos,Type)

%
if (isempty(hObj))
    if (Type == 2)
        hStr = get(hAx,'xticklabel');
        if (~iscell(hStr)); hStr = num2cell(hStr(:)',1); end
    else
        hStr = num2cell(get(hAx,'yticklabel'),2);
    end        
else
    hStr = get(hObj,'string');
end

% retrieves the object string
if (isempty(hStr))
    % if empty, then return a NaN-value array
    hDim = 0; 
    return
end

%
if (isempty(hObj))
    % otherwise, retrieve the font property data struct
    pFont = retFontProp(hAx);
    
    %
    hExt = cell2mat(cellfun(@(x)(getTextSize(hAx,x,pFont)),hStr(:),'un',0));
    hDim = max(hExt(:,2+Type)*axPos(2+Type));    
else
    % 
    hExt = getPanelPosPix(hObj,'Normalized','Extent');
        
    % sets the 
    if (hExt(Type) > 1)
        dhDim = sum(hExt(Type+[0 2])) - 1;
    else
        dhDim = -hExt(Type);
    end
    
    %
    hDim = dhDim*axPos(2+Type);
end
