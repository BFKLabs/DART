% --- resets the region positions (if there is any 
function iMov = resetRegionPos(iMov,szFrm,dpOfs)

% if there is no translation data, then exit the function
if isempty(iMov.dpInfo); return; end

% resets the regions using the image offset
for i = 1:length(iMov.iR)
    % ------------------------ %
    % --- ROW INDEX UPDATE --- %
    % ------------------------ %    
    
    % resets the row indices
    iMov.iR{i} = iMov.iR{i} + dpOfs(2);
    iMov.pos{i}(2) = iMov.pos{i}(2) + dpOfs(2);
    iMov.posO{i}(2) = iMov.posO{i}(2) + dpOfs(2);
    
    % determines if the new row indices are feasible
    if iMov.iR{i}(1) < 1
        % case is there are negative indices
        dY = iMov.iR{i}(1) - 1;
        
        % resets the region/sub-region row indices
        iMov.iR{i} = 1:iMov.iR{i}(end);
        iMov.iRT{i} = cellfun(@(x)(x+dY),iMov.iRT{i},'un',0);
        iMov.iRT{i}{1} = 1:iMov.iRT{i}{1}(end);        
        iMov.yTube{i} = max(0,iMov.yTube{i} + dY);
        
        % updates the region position vectors
        iMov.pos{i}([2,4]) = [1,iMov.pos{i}(4)+dY];
        iMov.posO{i}([2,4]) = [1,iMov.posO{i}(4)+dY];
        
    elseif iMov.iR{i}(end) > szFrm(1)
        % case is there are frames exceeding the frame edge
        dY = iMov.iR{i}(end) - szFrm(1);
        
        % resets the region/sub-region row indices
        iMov.iR{i} = iMov.iR{i}(1):szFrm(1); 
        iMov.iRT{i} = cellfun(@(x)(x+dY),iMov.iRT{i},'un',0);
        iMov.iRT{i}{end} = iMov.iRT{i}{end}(1):szFrm(1);        
        iMov.yTube{i} = min(szFrm(1)-1,iMov.yTube{i} + dY);  
        
        % updates the region position vectors
        iMov.pos{i}(4) = iMov.pos{i}(4)-dY;
        iMov.posO{i}(4) = iMov.posO{i}(4)-dY;
        
    end
    
    % --------------------------- %
    % --- COLUMN INDEX UPDATE --- %
    % --------------------------- %
    
    % resets the column indices
    iMov.iC{i} = iMov.iC{i} + dpOfs(1);
    iMov.pos{i}(1) = iMov.pos{i}(1) + dpOfs(1);
    iMov.posO{i}(1) = iMov.posO{i}(1) + dpOfs(1);
    
    % determines if the new column indices are feasible
    if iMov.iC{i}(1) < 1
        % case is there are negative indices
        dX = iMov.iC{i}(1) - 1;     
        
        % resets the region/sub-region row indices
        iMov.iC{i} = 1:iMov.iC{i}(end);     
        iMov.xTube{i} = [0,length(iMov.iC{i})-1];
        
        % updates the region position vectors
        iMov.pos{i}([1,3]) = [1,iMov.pos{i}(3)+dX];
        iMov.posO{i}([1,3]) = [1,iMov.posO{i}(3)+dX];
        
    elseif iMov.iC{i}(end) > szFrm(2)
        % case is there are frames exceeding the frame edge
        dX = iMov.iC{i}(end) - szFrm(2);        
        
        % resets the region/sub-region row indices
        iMov.iC{i} = iMov.iC{i}(1):szFrm(2); 
        iMov.xTube{i} = [0,length(iMov.iC{i})-1];
        
        % updates the region position vectors
        iMov.pos{i}(3) = iMov.pos{i}(3)-dX;
        iMov.posO{i}(3) = iMov.posO{i}(3)-dX;
        
    end    
end

% clears any other fields
iMov.dpInfo = [];