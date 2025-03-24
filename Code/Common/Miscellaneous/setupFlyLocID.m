function cID = setupFlyLocID(iMov,isSave)

% sets the default input arguments
if ~exist('isSave','var'); isSave = false; end
isMltTrk = detMltTrkStatus(iMov);

% sets up the ID flags for each grouping
if isMltTrk
    % sets the group numbers and group indices
    gNameU = unique(iMov.pInfo.gName,'Stable');
    
    % memory allocation
    nGrp = length(gNameU);  
    cID = cell(nGrp,1);
    
    % field retrieval
    fOK = iMov.flyok'; 
    nFlyR = iMov.pInfo.nFly';    
    iGrp = iMov.pInfo.iGrp';    

    % loops through each group setting the row/column/group indices    
    for i = 1:nGrp
        % sets the group index ID flags
        idx = find(iGrp.*fOK == i);
        cIDnw0 = arrayfun(@(x,y)([x*ones(y,1),(1:y)']),...
                                idx,nFlyR(idx),'un',0);
        cIDnw = cell2mat(cIDnw0(:));            
        
        % appends the indices to the overall array
        cID{i} = [cID{i};cIDnw];        
    end

    % sorts the ID arrays by column and then by row (for each unique group)
    for i = 1:nGrp
        if ~isempty(cID{i})
            cID{i} = sortrows(cID{i},[1,2]);
        end
    end    
    
elseif iMov.is2D 
    % case is a 2D experiment setup    
    
    % sets the group numbers and group indices
    if isSave
        [~,~,iC] = unique(iMov.pInfo.gName,'Stable');
    else
        iC = 1:length(iMov.pInfo.gName);
    end
        
    % memory allocation
    nGrp = max(iC);  
    cID = cell(nGrp,1);
    iGrp = iMov.pInfo.iGrp;

    % loops through each group setting the row/column/group indices    
    for i = 1:length(iC)
        % case is 2D single tracking
        [iy,ix] = find(iGrp==i);
        cIDnw = [iy(:),ix(:),i*ones(length(ix),1)];        
        
        % appends the indices to the overall array
        cID{iC(i)} = [cID{iC(i)};cIDnw];
    end
    
    % sorts the ID arrays by column and then by row (for each unique group)
    for i = 1:nGrp
        cID{i} = sortrows(cID{i},[2,1]);
    end
else
    % case is a 1D experiment setup
    
    % determines if the setup has a custom configuration
    isCust = detIfCustomGrid(iMov);    
    
    % sets the ID flags for each region/grouping
    iGrp = zeros(size(iMov.flyok));
    [iCol,iRow] = deal(zeros(size(iMov.flyok,2),1));
    for i = 1:size(iGrp,2)
        % retrieves the column/row indices
        [iCol(i),~,iRow(i)] = getRegionIndices(iMov,i);
        
        % determines if the ok flag has been set
        if isCust
            % case is a custom grid setup
            gID = iMov.pInfo.gID{iRow(i),iCol(i)};
            iGrp(iMov.flyok(:,i),i) = gID;
            
        else
            % case is a fixed grid setup
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
        if isCust
            cID = cell(nGrp,1);
        else
            cID = cell(size(iGrp,2),1);
        end
        
        for i = 1:nGrp
            % determines the matching group indices
            [iy,ix] = find(iGrp == iGrpU(i));
            
            % sets the group 
            if isCust
                % case is a custom grid setup
                cID{i} = [iRow(ix),iCol(ix),iy];
                
            else
                % case is a fixed grid setup
                for iApp = unique(ix(:))'
                    ii = ix == iApp;
                    cID{iApp} = [iRow(ix(ii)),iCol(ix(ii)),iy(ii)];
                end
            end
        end
    end
end
