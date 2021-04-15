% --- determines if there are any multiple x/y labels on a plot
function isMulti = getMultiLabel(hAx,nD,lStr)

%
if (nD == 1)
    % if only one subplot in the given dimension, then exit
    isMulti = false;
    return
else
    % determines the 
    isY = strcmp(lStr,'yLabel');
    [hLbl,isMulti] = deal(get(hAx,lStr),false);        
    hLbl(cellfun(@(x)(isempty(get(x,'string'))),hLbl)) = {[]};
    
    
    %
    if (length(hLbl) > 1)
        % retrieves the axis/legend positions
        axP = get(hAx,'position');
        if (iscell(axP)); axP = cell2mat(axP); end

        % determines unique axis in the search dimension
        dim = NaN(1,2);
        [~,b,c] = unique(roundP(axP(:,1+isY),0.01));
        
        %
        ii = cellfun(@(x)(find(c == x)),num2cell(b),'un',0);
        jj = cellfun(@length,ii) == nD;        
        [b,c] = deal(b(jj),c(cell2mat(ii(jj))));
        hLbl = hLbl(cell2mat(ii(jj)));
        
        %
        [dim(1+isY),dim(1+~isY)] = deal(nD,length(b));
        hLblL = cell(dim);        
        
        % sets the labels in position wrt to the plot axis        
        for i = 1:length(b)
            kk = find(c == b(i));
            if (isY)
                % case is searching for y-labels
                hLblL(i,:) = hLbl(kk);
            else
                % case is searching for x-labels
                hLblL(:,i) = hLbl(kk);
            end
        end
        
        % determines if there are any multiple labels in the row/column
        isMulti = any(sum(~cellfun(@isempty,hLblL),1+isY) > 1);
    end    
end
