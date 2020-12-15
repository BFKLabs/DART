% --- adds in the errorbars to the data on the axis, hAx --- %
function hErr = addBarError(hAx,xi,Y,Ysem,col,lWid)

% sets the default parameters (if not provided)
if (nargin < 6); lWid = 2.5; end
pW = 0.75;

% initialisations and parameters
if (isempty(xi)); xi = 1:length(Y); end
xLim = reshape(xi([1 end]),1,2) + 0.5*[-1 1];

% retrieves the bar patch x-locations
if (verLessThan('matlab','8.4'))    
    if (strcmp(get(hAx,'type'),'hggroup'))
        %
        xData = get(get(hAx,'children'),'xdata');
        [xi,W] = deal(mean(xData,1),(max(xData(:,1))-min(xData(:,1))));

        %
        hAx = get(hAx,'parent');
    else
        hP = findall(hAx,'tag','hBar');
        if (~isempty(hP))
            % retrieves the x-data from the bar plots
            xData = get(get(hP(1),'children'),'xdata');   
            if (isempty(xData))
                xData = get(hP(1),'xdata');        
            end
            W = (max(xData(:,1))-min(xData(:,1)));   
        else        
            hL = findall(hAx,'tag','hLine');
            if (~isempty(hL))
                W = xi(end)*diff(xLim)/(max(xi)-min(xi)+1);
            else
                W = range(xi);
            end
        end
    end
end
    
% sets the upper/lower SEM limits
if (iscell(Ysem))
    if (iscell(Ysem{1}))
        [YL,YU] = deal(Ysem{1}{1}-Y,max(Ysem{1}{2}-Y,0));
    else
        [YL,YU] = deal(Ysem{1}-Y,max(Ysem{2}-Y,0));
    end
else
    dYL = Ysem - reshape(Y,size(Ysem));
    [YU,YL] = deal(Ysem,Ysem - dYL.*(dYL > 0));
end

%
[YU(YU == 0),YL(YL == 0)] = deal(NaN);

% plots the error bars
if (verLessThan('matlab','8.4'))    
    hErr = errorbar(hAx,xi,Y,YL,YU,'.','markersize',1,'linewidth',lWid,'color',col);
    errorbar_tick(hErr,pW*W,'Units'); 
else
    %
    if (strcmp(hAx.Type,'bar'))
        hPE = get(hAx,'Parent');
    else
        hPE = hAx;
    end
        
    %
    hErr = errorbar(hPE,xi,Y,YL,YU,'.','markersize',1,'linewidth',lWid,...
                                       'color',col,'tag','hErr');
        
    % sets the cap-size (wrt to the bar widths)
    axP = getPanelPosPix(hPE,'points'); 
    hP = findall(hPE,'type','Bar');
    hErr.CapSize = 0.75*pW*hP(1).BarWidth*axP(3)/length(xi);
end
