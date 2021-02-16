% --- creates a bar plot with two differing axis, but with the same x
%     values. original plot is given in the axis object, hAx1
function [hAx,hBar,hErr] = plotDoubleAxisBar(hAx1,X,Y1,Y2,pW,pF,nTick0,yMax,ySEM,zSEM)

% sets the default width to 1
if (nargin < 5); pW = 1; end
if (nargin < 7); nTick0 = 6; end

% creates the new legend    
[col,hErr] = deal('br',NaN(1,2));
pF.Legend.String = {'\tau_{Fast}','\tau_{Slow}'};

% creates the second axis
hAx2 = copyobj(hAx1,get(hAx1,'parent'));
set(hAx2,'YAxisLocation','right','Color','none','Ycolor',col(2),'ticklength',[0 0]);
set(hAx1,'Ycolor',col(1),'ticklength',[0 0]);
hAx = [hAx1,hAx2];        

% sets hold on to both axis
hold(hAx1,'on'); hold(hAx2,'on');

% adds the errorbars/limits for the 1st axis
if (~isempty(ySEM))
    % SEM values included, so add error bar
    [yMax1b,Y1ax] = deal(nanmax(yMax(1),max(Y1+ySEM)),Y1+ySEM);
else
    % no SEM values included
    [yMax1b,Y1ax] = deal(nanmax(yMax(1),max(Y1)),Y1);
end

% adds the errorbars/limits for the 2nd axis
if (~isempty(zSEM))
    % SEM values included, so add error bar
    yMax2b = nanmax(yMax(2),max(Y2+zSEM));
else
    % no SEM values included
    yMax2b = nanmax(yMax(2),max(Y2));
end

% resets the 
if (nargin >= 8)            
    yMax1 = setStandardYAxis(hAx1,Y1ax,nTick0,yMax1b);    
    yMax2 = setStandardYAxis(hAx2,Y2,nTick0,yMax2b);
else
    yMax1 = setStandardYAxis(hAx1,Y1,nTick0);
    yMax2 = setStandardYAxis(hAx2,Y2,nTick0);    
end

% sets the 
R = yMax1/yMax2;
if (length(X) == 1)
    dX = 1/4;
else
    dX = diff(X([1 2]))/4;
end

% plots the two axis side-by-side (scaled by the parameter, pW)
hBar = cell(2,1);
hBar{1} = bar(hAx1,X-pW*dX,Y1,pW/2,col(1),'tag','hBar');
hBar{2} = bar(hAx1,X+pW*dX,Y2*R,pW/2,col(2),'tag','hBar');

% resets the legend location/orientation
if (nargin == 6) 
    if (~isempty(pF))
        createLegendObj(cell2mat(hBar),pF.Legend,1)
        hLg = findall(get(hAx1,'parent'),'tag','legend');
        set(hLg,'Location','North','Orientation','horizontal');
    end
end

% adds the errorbars/limits for the 1st axis
if (~isempty(ySEM))
    % SEM values included, so add error bar
    dXE = pW*dX*(~isempty(zSEM));
    hErr(1) = addBarError(hBar{1},X-dXE,Y1,ySEM,'g');
end

% adds the errorbars/limits for the 2nd axis
if (~isempty(zSEM))
    % SEM values included, so add error bar
    hErr(2) = addBarError(hBar{2},X+pW*dX,Y2*R,zSEM*R,'g');                            
end

% % resets the axis limits                                
% set(hAx(1),'ylim',[0 yMax1]*pR)
% set(hAx(2),'ylim',[0 yMax2]*pR)