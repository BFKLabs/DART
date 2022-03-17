% --- optimises the position of the figures given in hFigL
function optFigPosition(hFigL)

%
switch length(hFigL)
    case 1
        % case is a single figure 
        
        % centres the figure
        centreFigPosition(hFigL)
        
    case 2
        % case are 2 figures
        
        % retrieves the screena and figure position vectors
        scrSz = getPanelPosPix(0,'Pixels','ScreenSize');
        pFig = cell2mat(arrayfun(@(x)(get(x,'Position')),hFigL(:),'un',0));
        
        % determines which alignment is optimal
        pOverlap = sum(pFig(:,3:4),1)./scrSz(3:4);
        iDim = argMin(pOverlap);
        
        %
        if iDim == 1        
            % sets the figure horizontal placement
            if pOverlap(1) > 1
                pFig(:,1) = [1,scrSz(3)-pFig(2,3)];
            else
                dX = (scrSz(3) - sum(pFig(:,3)))/3;
                pFig(:,1) = [dX,2*dX+pFig(1,3)];
            end
            
            % sets the figure vertical placement
            pFig(:,2) = (scrSz(4)-pFig(:,4))/2;
        else
            % sets the figure vertical placement
            if pOverlap(2) > 1
                pFig(:,2) = [1,scrSz(4)-pFig(2,4)];
            else
                dY = (scrSz(4) - sum(pFig(:,4)))/3;
                pFig(:,1) = [dY,2*dY+pFig(1,4)];
            end            
            
            % sets the figure horizontal placement
            pFig(:,1) = (scrSz(3)-pFig(:,3))/3;
        end
        
        % resets the figure positions
        arrayfun(@(x)(set(hFigL(x),'Position',pFig(x,:))),1:2);
        pause(0.05)
        
    otherwise
        % case is >2 figures
        waitfor(msgbox('Finish Me!'))
        
end