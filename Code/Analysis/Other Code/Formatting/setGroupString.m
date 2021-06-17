% --- sets the group string x-labels onto the axis, hAx --- %
function setGroupString(hAx,pF,Tbin,xStr,tRot,dY0,ind)

% sets the default parameter values (if not provided)
if (nargin < 5); tRot = -90; end
if (nargin < 6); dY0 = 0; end
if (nargin < 7); ind = 1; end
if (~iscell(xStr)); xStr = {xStr}; end

if (~iscell(hAx))
    if (length(hAx) == 1)
        hAx = {hAx}; 
    else
        hAx = num2cell(hAx);
    end
end

% ensures the rotation angle is between -90 to 90
[tRot,yScale] = deal(mod(tRot+180,360)-180,get(hAx{1},'yscale'));
set(hAx{1},'yScale','linear');

% parameters
[yOfsL,y0] = deal(0.02,min(get(hAx{1},'ylim')));

% memory allocations
[nGrp,tRotR,Wmax] = deal(length(Tbin),tRot*pi/180,0.99);
if (nGrp == 1); xStr = {''}; end

% set group strings
xTick = get(hAx{1},'xtick')';
if (isempty(xTick)); xTick = (1:length(Tbin))'; end
if (length(xTick) ~= nGrp); xTick = Tbin; end
set(hAx{1},'xticklabel',[]);
   
% creates the text objects and retrieves the x-label handle                           
xTick = num2cell(reshape(xTick,size(xStr)));
try    
    h = cellfun(@(x,y)(text(x,y0,y,'parent',hAx{1})),xTick,xStr,'un',0);
catch
    h = cell(size(xStr));
    for i = 1:length(h)
        h{i} = text(xTick{i},y0,xStr{i},'parent',hAx{1});
    end
end

% updates the font properties
cellfun(@(x)(set(x,'Units','Normalized')),h)
updateFontProps(h,pF.Axis(ind).Font,1,'Axis') 
h = reshape(h,length(h),1);

% sets the units to be normalised and retrieves the text object extents
% cellfun(@(x)(set(x,'Units','Normalized')),h)
xPos = cell2mat(cellfun(@(x)(get(x,'Extent')),h,'un',0));

% retrieves the axis position and set the text label extents/aspect ratio
set(hAx{1},'Units','Normalized')
[WD,HD] = deal(xPos(:,3),xPos(:,4));
axPos = get(hAx{1},'position');

% shifts the bottom up by half the height and rotates the labels
cellfun(@(x,y)(resetObjPos(x,'bottom',-y/2,1)),h,num2cell(HD));
 
% offsets the x/y locations of the labels
cellfun(@(x)(set(x,'rotation',tRot)),h);
cellfun(@(x,y)(resetObjPos(x,'left',-y,1)),h,num2cell(cos(tRotR)*WD/2));
set(hAx{1},'yscale',yScale)

% determines the change in the height of the axis (due to the rotation)
xPos0 = cell2mat(cellfun(@(x)(get(x,'Extent')),h,'un',0));
[dH,dyOfs] = deal(max(xPos0(:,4) - HD),yOfsL);

% resets the x-label (if one has been created)
hXlbl = findall(hAx{1},'tag','xLabel'); 
if (~isempty(hXlbl))
    % retrieves the axis object property position/extent vectors
    set(hXlbl,'Units','Normalized');
    [xExt,xPos1] = deal(get(hXlbl,'Extent'),get(hXlbl,'Position'));
    
    xStr = get(hXlbl,'string');
    if (length(xStr) == 1) && (uint8(xStr(1)) == 32)    
        dyOfs = xExt(4);   
    end
end

% resets the axis position
[Bnw,Hnw] = deal(axPos(2)+(dH+dyOfs)*axPos(4),axPos(4)*(1-(dH+dyOfs)));
set(hAx{1},'Position',[axPos(1),Bnw,axPos(3),Hnw])
xPosNw = cell2mat(cellfun(@(x)(get(x,'Extent')),h,'un',0));

% resets the width of the axes so the labels are within the axes frame
WmaxP = max(axPos(1)+sum(xPosNw(:,[1 3]),2)*axPos(3));
if (WmaxP > Wmax)
    dW = (Wmax-WmaxP)/axPos(3);
    resetObjPos(hAx{1},'width',dW,-1);
    xPosNw = cell2mat(cellfun(@(x)(get(x,'Extent')),h,'un',0));
end

% resets the 
if (tRot > 0)        
    yNw = -(xPosNw(:,4)-xPos(:,4)+dyOfs); 
    cellfun(@(x,y)(resetObjPos(x,'bottom',y)),h,num2cell(yNw));
    xPosNw = cell2mat(cellfun(@(x)(get(x,'Extent')),h,'un',0));
end

% resets the x-label position (if it exists)
if (~isempty(hXlbl))    
    Bnw = -max(xPosNw(:,4))-dY0;            
    set(hXlbl,'position',[xPos1(1),Bnw,0]);     
    xPosNw = cell2mat(cellfun(@(x)(get(x,'Extent')),h,'un',0));
end

% ensures the height of all the 
dY = num2cell((xPosNw(:,4)-max(xPosNw(:,4)))/2);
cellfun(@(x,y)(resetObjPos(x,'bottom',y,1)),h,dY);

% resets the position of the 2nd axis
if (length(hAx) == 2)
    set(hAx{2},'yScale',yScale);
    set(hAx{2},'units','normalized','position',get(hAx{1},'position'))    
end
