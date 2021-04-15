% --- determines the most square configuration for an array that has a
%     total of nRow/nCol rows and columns respectively
function [nRowMin,nColMin] = detMostSquareSetup(hAx,nRow)

% initialisations
[nRowMin,nColMin,ARbest,iter] = deal(nRow,1,1e10,1);

% keep looping until the minimum configuration is found
while (1)
    %
    [nRowNw,nColNw] = deal(ceil(nRow/iter),iter);
    set(hAx,'TickLength',[0 0],'xlim',[0 nColNw],'yLim',[0 nRowNw]);    
    pPos = getPanelPosPix(hAx);
    
    % calculates the new perimeter
    ARnw = abs((nRowNw/nColNw)*(pPos(3)/pPos(4)) - 1);
    if (ARnw < ARbest)
        % if the new perimeter is better, then reset the row/columns
        ARbest = ARnw;
        [iter,nRowMin,nColMin] = deal(iter + 1,ceil(nRow/iter),iter);
    else
        % otherwise, exit the loop
        break
    end
end