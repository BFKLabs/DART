% --- resets the position of the legend if the patch/line objects overlap
%     with the text objects, or the legend overlaps with the axes edge
function resetLegendPos(hLg,hAx)

% converts the axis cell array to a numerical array
if (~iscell(hAx))
    if (length(hAx) == 1)
        hAx = {hAx}; 
    else
        hAx = num2cell(hAx);
    end
else
    hAx = hAx(:);    
end

% initialisations and parameters
set(hLg,'Units','Normalized')
[dDim,hP,uStr] = deal(0.01,get(hLg,'Parent'),get(hLg,'Units'));
[pPos,lgP] = deal(getPanelPosPix(hP),get(hLg,'position'));

% determines the orientation of the legend
dim = 1 + strcmp(get(hLg,'Orientation'),'horizontal');
[k,pOfs] = deal(find((1:2) ~= dim),0.01);                   

% resets the width of the legend (if legend has vertical orientation)
if (dim == 1)
    lgP = resetVertLegendWidth(hLg,lgP);    
end

% updates the left/bottom position
if (sum(lgP([0 2]+dim)) > 0.5)
    % case is on the right/top part of graph
    [lgP(dim),isHi] = deal(1-(lgP(dim+2)+pOfs/2),true);
else
    % case is on the left/bottom part of graph
    [lgP(dim),isHi] = deal(0,false);
end

% sets the corresponding left/bottom dimension of the legend
lgP(k) = 0.5*(1 - lgP(k+2));
lgP = lgP.*repmat(pPos(3:4),1,2);

% resets the legend object properties based on the legend orientation
if (strcmp(get(hLg,'Orientation'),'horizontal'))
    % determines if the legend is greater than width of the axis
    if (lgP(1) < dDim*pPos(3)) || (lgP(3) > pPos(3)*(1-2*dDim))
        % updates the legend position
        lgP([1 3]) = [dDim*pPos(3),(1-2*dDim)*pPos(3)];
        updateLegendPos(hLg,lgP,uStr)        

        % resets the legend object location properties
        resetLegendObjProps(hLg,dDim,1);                
    else
        % otherwise, update the position of the legend normally
        updateLegendPos(hLg,lgP,uStr) 
    end
else
    % determines if the legend is greater than height of the axis
    if (lgP(2) < dDim*pPos(4)) || (lgP(4) > pPos(4)*(1-2*dDim))
        % updates the legend position
        lgP([2 4]) = [dDim*pPos(4),(1-2*dDim)*pPos(4)];
        updateLegendPos(hLg,lgP,uStr)        

        % resets the legend object location properties
        resetLegendObjProps(hLg,dDim,2);  
    else
        % otherwise, update the position of the legend normally
        updateLegendPos(hLg,lgP,uStr)         
    end    
end

% retrieves the axis positions
lgP = get(hLg,'position');
axPos = cell2mat(cellfun(@(x)(get(x,'position')),hAx,'un',0));
if (iscell(axPos)); axPos = cell2mat(axPos); end

%
xLo = min(axPos(:,dim));
if (dim == 2)
    % determines the position of the titles
    if (length(hAx) == 1)
        tPos = getPanelPosPix(get(hAx{1},'title'),'normalized','extent');
    else
        tPos = cell2mat(cellfun(@(x)(getPanelPosPix(...
            get(x,'title'),'normalized','extent')),hAx,'un',0));
    end
    
    % calculates the top most title
    xHi = max(axPos(:,dim)+sum(tPos(:,[2 4]),2).*axPos(:,dim+2));
else    
    % calculates the right most axes edge
    xHi = max(sum(axPos(:,[1 3]),2));    
end

% determines the new positions for the lower/upper dimension
if (isHi)
    % case is the legend is in the top/right of the axes
    [xLoNw,xHiNw] = deal(xLo,lgP(dim));
else
    % case is the legend is in the bottom/left of the axes
    [xLoNw,xHiNw] = deal(sum(lgP([0 2]+dim)),xHi);        
end
    
% calculates the change in axis width/height that is required
axPos(:,dim) = (axPos(:,dim)-xLo)*(xHiNw/xHi) + xLoNw;
axPos(:,dim+2) = axPos(:,dim+2)*(xHiNw - xLoNw)/(xHi - xLo) - pOfs;

%
for i = 1:length(hAx)
    set(hAx{i},'position',axPos(i,:));
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- updates the legend position
function updateLegendPos(hLg,lgP,uStr)

% resets the legend position
set(hLg,'Units','Pixels')
set(hLg,'position',lgP)
set(hLg,'Units',uStr)

% --- 
function resetLegendObjProps(hLg,dDim,dim)

% sets the position type
pType = {'xdata','ydata'};

% determines the required change in width
hP = [findall(hLg,'type','patch');findall(hLg,'type','line')];        
hT = findobj(hLg,'type','text');

% sorts the objects in ascending x-order
pData = get(hP,pType{dim});
pData = pData(cellfun('length',pData)>1);
[~,ii] = sort(cellfun(@(x)(x(dim)),pData));
[hP,pData,hT] = deal(hP(ii),pData(ii),hT(ii));

% retrieves the position/extent of the text objects
pExt = get(hT,'extent');

% determines if the position of the patch and text objects overlap
xLo = cellfun(@(x)(x(dim)),pData);
xHi = cellfun(@(x)(sum(x([0 2]+dim))),pExt);
ii = find(xLo(2:end) < xHi(1:(end-1))); 

% calculates the overlap of the text object with the axes edge
lgPnw = get(hLg,'position');
Wofs = max(0,lgPnw(dim+2)-(1-2*dDim));

% if there is an overlap, then reset the object positions        
if (~isempty(ii) || (Wofs > 0))
    % sets position offset
    if (isempty(ii))
        dP = Wofs;
    else
        dP = max(xHi(ii)-xLo(ii+1)) + Wofs;
    end

    % updates the position of the patch/text objects
    for j = 1:length(hP)
        % calculates the x-offset
        tPos = get(hT(j),'position');
        xOfs = tPos(dim) - pData{j}(dim+2);   

        % sets the patch/line x-location
        pData{j}(3:4) = pData{j}(3:4) - dP;                        
        set(hP(j),pType{dim},pData{j});

        % sets the text object x-location
        tPos(dim) = pData{j}(dim+2) + xOfs;
        set(hT(j),'position',tPos);                
    end
end