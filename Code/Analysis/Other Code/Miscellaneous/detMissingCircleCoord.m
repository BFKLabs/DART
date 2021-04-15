% --- 
function autoP = detMissingCircleCoord(iMov)

if iscell(iMov.iR{1})
    % array indexing and memory allocation
    nColS = length(iMov.iR{1});
    nCol = length(iMov.iR)*nColS;
    nRow = length(iMov.iR)*(length(iMov.iRT{1})/nCol);
    [X0,Y0] = deal(zeros(nRow,nCol));

    %
    for i = 1:length(iMov.iR)
        for j = 1:nColS
            %
            iCol = (i-1)*nColS + j;
            kGrp = (j-1)*nRow + (1:nRow);
            iRT = iMov.iRT{i}(kGrp);
            
            %
            y0 = iMov.iR{i}{j}(1)-1;
            Y0(:,iCol) = cellfun(@mean,iRT)+y0;
            X0(:,iCol) = mean(iMov.iC{i}{j});
        end
    end
    
else
    nCol = length(iMov.iR);
    msgbox('Finish Me!')
end


R0 = floor(0.9 * mean(mean(diff(Y0,[],1)))/2);
autoP = struct('X',X0,'Y',Y0,'R',R0,'Type','Circle','B',[]);