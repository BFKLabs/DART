% --- sets the limits of the sub-region
function [xLim,yLim] = setSubImageLimits(hAx,xLimAx,yLimAx,iMov,rPos,iApp)

% sets the row/column iAppices
[nRow,nCol] = deal(iMov.nRow,iMov.nCol);
[iR,iC] = deal(floor((iApp-1)/nCol)+1,mod(iApp-1,nCol)+1);

% sets the dimensions of the 
[L,T,W,H] = deal(rPos(1),rPos(2),rPos(3),rPos(4));
[dW,dH] = deal(W/nCol,H/nRow);

% sets the limits based on the type
if (iMov.isOpt)
    % case is regions have been optimised
    [hV,hH] = deal(findobj(hAx,'tag','vLine'),findobj(hAx,'tag','hLine'));        
        
    % sets the details for the vertical lines
    [ivL,xV] = deal(get(hV,'UserData'),get(hV,'xdata'));
    switch (length(ivL))
        case (0)
            xGap = [];
        case (1)
            xGap = xV(1);
        otherwise
            % sets the data into numerical arrays (if stored as cell arrays)
            [ivL,xV] = deal(cell2mat(ivL),cell2mat(xV)); 
            xGap = xV(ivL,1);
    end        
    
    % sets the details for the horizontal lines
    [ihL,yH] = deal(get(hH,'UserData'),get(hH,'ydata'));    
    switch (length(ihL))
        case (0)
            yGap = [];
        case (1)
            yGap = yH(1);    
        otherwise
            % sets the data into numerical arrays (if stored as cell arrays)
            [ihL,yH] = deal(cell2mat(ihL),cell2mat(yH)); 
            yGap = yH(ihL,1);        
    end
    
    %
    [XX,YY] = deal([L;xGap;(L+W)]',[T;yGap;(T+H)]');
    [xLim,yLim] = deal(XX(iC+(0:1)),YY(iR+(0:1)));
else
    % case is regions have not been optimised
    [xLim,yLim] = deal(L + (iC-1)*dW + [0 dW],T + (iR-1)*dH + [0 dH]);    
end

% ensures the limits are within the outer region limits
xLim = [max(xLimAx(1),xLim(1)) min(xLimAx(2),xLim(2))];
yLim = [max(yLimAx(1),yLim(1)) min(yLimAx(2),yLim(2))];    