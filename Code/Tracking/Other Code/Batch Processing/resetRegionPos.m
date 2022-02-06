% --- resets the region positions (if there is any 
function iMov = resetRegionPos(iMov,szFrm,dpOfs)

% resets the regions using the image offset
for i = 1:length(iMov.iR)
    % ------------------------ %
    % --- ROW INDEX UPDATE --- %
    % ------------------------ %    
    
    % resets the row indices
    iMov.iR{i} = iMov.iR{i} + dpOfs(2);
    iMov.pos{i}(2) = iMov.pos{i}(2) + dpOfs(2);
    iMov.posO{i}(2) = roundP(iMov.posO{i}(2) + dpOfs(2));
    
    % determines if the new row indices are feasible
    if iMov.iR{i}(1) < 1
        % case is there are negative indices
        ii = iMov.iR{i} >= 1;
        dY = 1 - iMov.iR{i}(1);
        
        % resets the region/sub-region row indices
        iMov.iR{i} = iMov.iR{i}(ii);
        iMov.iRT{i} = cellfun(@(x)(x-dY),iMov.iRT{i},'un',0);
        iMov.iRT{i}{1} = iMov.iRT{i}(iMov.iRT{i} >= 1);
        iMov.yTube{i} = max(0,iMov.yTube{i} - dY);
        iMov.pos{i}([2,4]) = [1,iMov.pos{i}(4) - dY];  
        iMov = resetExclusionBin(iMov,ii,i,1);
        
        
    elseif iMov.iR{i}(end) > szFrm(1)
        % case is there are frames exceeding the frame edge
        ii = iMov.iR{i} <= szFrm(1);
        dY = iMov.iR{i}(end) - szFrm(1);
        
        % resets the region/sub-region row indices
        iMov.iR{i} = iMov.iR{i}(ii); 
        iMov.iRT{i}{end} = iMov.iRT{i}{end}(1):sum(ii);        
        iMov.yTube{i} = min(szFrm(1)-1,iMov.yTube{i}+dY);  
        iMov.pos{i}(4) = iMov.pos{i}(4)-dY;         
        iMov = resetExclusionBin(iMov,ii,i,1);
        
    end              
    
    % determines if the outer region dimensions are feasible
    if iMov.posO{i}(2) < 1
        % the outer region extends past the top edge
        dY = 1 - iMov.posO{i}(2);
        iMov.posO{i}([2,4]) = [1,iMov.posO{i}(4) - dY];
       
    elseif sum(iMov.posO{i}([2,4])) > szFrm(1)
        % the outer region extends past the right edge
        dY = sum(iMov.posO{i}([2,4])) - szFrm(1);
        iMov.posO{i}(4) = iMov.posO{i}(4) - dY; 
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
        jj = iMov.iC{i} >= 1;
        dX = 1 - iMov.iC{i}(1);     
        
        % resets the region/sub-region row indices
        iMov.iC{i} = 1:iMov.iC{i}(end);     
        iMov.xTube{i} = [0,length(iMov.iC{i})-1];
        
        % updates the region position vectors
        iMov.pos{i}([1,3]) = [1,iMov.pos{i}(3) - dX];
        iMov.posO{i}([1,3]) = [1,iMov.posO{i}(3) - dX];
        iMov = resetExclusionBin(iMov,jj,i,2);
        
    elseif iMov.iC{i}(end) > szFrm(2)
        % case is there are frames exceeding the frame edge
        jj = iMov.iC{i} <= szFrm(2);
        dX = iMov.iC{i}(end) - szFrm(2);        
        
        % resets the region/sub-region row indices
        iMov.iC{i} = iMov.iC{i}(1):szFrm(2); 
        iMov.xTube{i} = [0,length(iMov.iC{i})-1];
        
        % updates the region position vectors
        iMov.pos{i}(3) = iMov.pos{i}(3) - dX;
        iMov.posO{i}(3) = iMov.posO{i}(3) - dX;
        iMov = resetExclusionBin(iMov,jj,i,2);
    end  
    
    % determines if the outer region dimensions are feasible
    if iMov.posO{i}(1) < 1
        % the outer region extends past the right edge
        dX = 1 - iMov.posO{i}(1);
        iMov.posO{i}([1,3]) = [1,iMov.posO{i}(3) - dX];
       
    elseif sum(iMov.posO{i}([1,3])) > szFrm(2)
        % the outer region extends past the right edge
        dX = sum(iMov.posO{i}([1,3])) - szFrm(2);
        iMov.posO{i}(3) = iMov.posO{i}(3) - dX; 
    end    
    
    % --------------------------- %
    % --- COLUMN INDEX UPDATE --- %
    % --------------------------- %
    
    % reshapes the coordinates
    iMov = resetAutoShapeCoords(iMov,dpOfs,i);    
    
end

% --- resets the binary mask
function iMov = resetExclusionBin(iMov,indNw,iApp,iDim)

switch iDim
    case 1
        % case is the row reduction
        switch iMov.autoP.Type
            case 'Circle'
                % case is the circular setup
                iMov.autoP.B{iApp} = iMov.autoP.B{iApp}(indNw,:);                
                
            case {'GeneralR','GeneralC'}
                % case is the general region setup
                iMov.autoP.BT{iApp} = iMov.autoP.BT{iApp}(indNw,:);
                
        end    
        
    case 2
        % case is the column reduction
        switch iMov.autoP.Type
            case 'Circle'
                % case is the circular setup 
                iMov.autoP.B{iApp} = iMov.autoP.B{iApp}(:,indNw);
                
            case {'GeneralR','GeneralC'}
                % case is the general region setup
                iMov.autoP.BT{iApp} = iMov.autoP.BT{iApp}(:,indNw);
                
        end                 

end

% --- resets the automatically detected shape coorinates
function iMov = resetAutoShapeCoords(iMov,dP,iApp)

% offsets the region coordinates
iMov.autoP.X0(:,iApp) = iMov.autoP.X0(:,iApp) + dP(1);
iMov.autoP.Y0(:,iApp) = iMov.autoP.Y0(:,iApp) + dP(2);
