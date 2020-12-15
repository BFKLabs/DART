% --- adds in the errorbars to the data on the axis, hAx --- %
function hErr = addBarHError(hAx,xi,X,Xsem,col,errWid)

% sets the default parameters (if not provided)
if (nargin < 6); errWid = 2.5; end

% initialisations and parameters
if (isempty(xi)); xi = 1:length(Y); end
yLim = reshape(xi([1 end]),1,2) + 0.5*[-1 1];

% retrieves the bar patch x-locations
if (strcmp(get(hAx,'type'),'hggroup'))
    %
    yData = get(get(hAx,'children'),'ydata');
    [xi,W] = deal(mean(yData,1)',(max(yData(:,1))-min(yData(:,1))));    
    hAx = get(hAx,'parent');
else
    hP = findall(hAx,'tag','hBar');
    if (~isempty(hP))
        % retrieves the x-data from the bar plots
        yData = get(get(hP(1),'children'),'ydata');   
        if (isempty(yData))
            yData = get(hP(1),'ydata');        
        end

        W = (max(yData(:,1))-min(yData(:,1)));    
    else
        hL = findall(hAx,'tag','hLine');
        if (~isempty(hL))
            W = xi(end)*diff(yLim)/(max(xi)-min(xi)+1);
        else
            W = range(xi);
        end
    end
end
    
% plots the error bars
hErr = herrorbar(X,xi,Xsem,'.');
set(hErr,'markersize',1,'linewidth',errWid,'color',col);
errorbarH_tick(hErr,0.75*W,'Units'); 