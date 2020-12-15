% --- adds the scatterplot errorbars
function addScatterError(hAx,X,Y,Xsem,Ysem,col,errWid)

% sets the default parameters (if not provided)
if (nargin < 7); errWid = 1.5; end

% initialisations
[xLim,yLim,pW] = deal(get(hAx,'xlim'),get(hAx,'ylim'),0.01);

% creates the x-direction SEM values
if (~isempty(Ysem))
    % creates the errorbars
    errorbar(hAx,X,Y,Ysem,'.','markersize',1,'linewidth',errWid,'color',col)
    
    % recalculates the x axis limits
    yLim = [min(Y-Ysem) max(Y+Ysem)];
end

% creates the y-direction SEM values
if (~isempty(Xsem))
    % creates the errorbars
    hErr = herrorbar(X,Y,Xsem,'.');
    set(hErr,'markersize',1,'linewidth',errWid,'color',col);
    
    % recalculates the x axis limits
    xLim = [min(X-Xsem) max(X+Xsem)];
end

% resets the axis limits
set(hAx,'xlim',xLim+pW*diff(xLim)*[-1 1],'ylim',yLim+pW*diff(yLim)*[-1 1])