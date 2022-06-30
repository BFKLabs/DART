function cID = setupFlyLocID(iMov,isSave)

% sets the default input arguments
if ~exist('isSave','var'); isSave = false; end
isMltTrk = detMltTrkStatus(iMov);

% sets up the ID flags for each grouping
if iMov.is2D || isMltTrk
    % case is a 2D experiment setup    
    iGrp = iMov.pInfo.iGrp;
    
    % sets the group numbers and group indices
    if isSave
        [~,~,iC] = unique(iMov.pInfo.gName,'Stable');
    else
        iC = 1:length(iMov.pInfo.gName);
    end
        
    % memory allocation
    nGrp = max(iC);  
    cID = cell(nGrp,1);

    % loops through each group setting the row/column/group indices    
    for i = 1:length(iC)
        % determines the regions with the current grouping           
        if isMltTrk
            % case is for multi-tracking
            idx = find(iGrp==i);
            cIDnw0 = cellfun(@(x,y)([x*ones(sum(y),1),find(y(:))]),...
                                    num2cell(idx),iMov.flyok(idx),'un',0);
            cIDnw = cell2mat(cIDnw0(:));
        else
            % case is 2D single tracking            
            [iy,ix] = find(iGrp==i);
            cIDnw = [iy,ix,i*ones(length(ix),1)];
        end
        
        % appends the indices to the overall array
        cID{iC(i)} = [cID{iC(i)};cIDnw];
    end
    
    % sorts the ID arrays by column and then by row (for each unique group)
    for i = 1:nGrp
        if isMltTrk
            cID{i} = sortrows(cID{i},[1,2]);

        else
            cID{i} = sortrows(cID{i},[2,1]);
        end
    end
else
    % case is a 1D experiment setup
    iGrp = zeros(size(iMov.flyok));
    [iCol,iRow] = deal(zeros(size(iMov.flyok,2),1));
    for i = 1:size(iGrp,2)
        % retrieves the column/row indices
        [iCol(i),~,iRow(i)] = getRegionIndices(iMov,i);
        
        % determines if the ok flag has been set
        iGrpG = iMov.pInfo.iGrp(iRow(i),iCol(i));        
        if iGrpG == 0
            isOK = false;
        else
            isOK = iMov.ok(i);
        end
        
        % updates the grouping flag
        if isOK
            iGrp(iMov.flyok(:,i),i) = iMov.pInfo.iGrp(iRow(i),iCol(i));
        end
    end
    
    % determines the number of unique groupings
    iGrpU = unique(iGrp(iGrp>0));
    nGrp = length(iGrpU);
    
    % sets the configuration ID arrays based on the I/O type
    %  - Saving: data is combined for each specified group
    %  - Loading: all data is separated by individual setup groups
    if isSave        
        % memory allocation
        cID = cell(nGrp,1);

        % loops through each group setting the row/column/fly indices
        for i = 1:nGrp
            [iy,ix] = find(iGrp == iGrpU(i));
            cID{i} = [iRow(ix),iCol(ix),iy];
        end
    else
        % memory allocation
        cID = cell(size(iGrp,2),1);
        
        for i = 1:nGrp
            [iy,ix] = find(iGrp == iGrpU(i));
            for iApp = unique(ix(:))'
                ii = ix == iApp;
                cID{iApp} = [iRow(ix(ii)),iCol(ix(ii)),iy(ii)];
            end
        end
    end
end
