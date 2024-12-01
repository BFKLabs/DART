% --- retrieves the region group names cell array
function gName = getRegionGroupNames(snTot)

% sets the group names
pInfo = snTot.iMov.pInfo;
[gName0,cID] = deal(pInfo.gName,snTot.cID);

if detMltTrkStatus(snTot.iMov)
    % case is a multi-experiment    
    
    % sets the final data/column headers
    ii = ~cellfun('isempty',snTot.cID);
    iReg = cellfun(@(x)(unique(x(:,1))),snTot.cID(ii),'un',0);
    nReg = max(cell2mat(iReg));
    
    if nReg == length(gName0)
        % if the group names length matches overall, then set as is
        gName = gName0;
        
    else
        % otherwise, set the names (for each grouping)
        gName = cell(nReg,1);    
        for i = 1:length(iReg)
            gName(iReg{i}) = gName0(i);
        end
    end
    
elseif snTot.iMov.is2D
    % case is a 2D experiment    
    
    % sets the final data/column headers
    ii = ~cellfun('isempty',snTot.cID);
    iReg = cellfun(@(x)(unique(x(:,end))),snTot.cID(ii),'un',0);
    nReg = max(cell2mat(iReg));
    gName = cell(nReg,1);
    
    % sets the group names (for each grouping)
    for i = 1:length(iReg)
        gName(iReg{i}) = gName0(iReg{i}(1));
    end
    
else
    % case is a 1D experiment    
    
    % determines if the number of regions equals the number of group names
    nReg = pInfo.nRow*pInfo.nCol;    
    if length(gName0) == nReg
        % if so, then return the stored group names
        gName = gName0(:);
    else
        % otherwise, re-order the group names
        gName = repmat({'* REJECTED *'},nReg,1);

        % sets the group names (for each grouping)
        for i = 1:length(cID)
            if ~isempty(cID{i})
                indM = unique(cID{i}(:,1:2),'rows');
                iReg = (indM(:,1)-1)*pInfo.nCol + indM(:,2);
                
                for j = 1:length(iReg)
                    iGrpNw = pInfo.iGrp(indM(j,1),indM(j,2));
                    gName(iReg(j)) = gName0(iGrpNw);
                end
            end
        end    
    end
    
    % determines if any groupings are missing from the configuration
    cIDT = cell2mat(cID(:));
    if detIfCustomGrid(snTot.iMov)
        % case is a custom grid setup
        gID = snTot.iMov.pInfo.gID;
        gIDT = combineNumericCells(arr2vec(gID')');
        isMiss = ~arrayfun(@(x)(any(gIDT(:)==x)),(1:length(gName))');
        
    else
        % case is a fixed grid setup
        szArr = size(snTot.iMov.flyok);
        iCol = (cIDT(:,1)-1)*snTot.iMov.pInfo.nCol + cIDT(:,2);
        isMiss = all(~setGroup(sub2ind(szArr,cIDT(:,3),iCol),szArr),1);  
    end
    
    % removes the missing groups
    gName(isMiss) = {'* REJECTED *'};    
end

