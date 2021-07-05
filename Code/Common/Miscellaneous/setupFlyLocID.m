function cID = setupFlyLocID(iMov)

% sets up the ID flags for each grouping
if iMov.is2D
    % case is a 2D experiment setup    
    iGrp = iMov.pInfo.iGrp;
    
    % sets the group numbers and group indices
    [gNameU,~,iC] = unique(iMov.pInfo.gName,'Stable');
    nGrp = length(gNameU);  
    
    % loops through each group setting the row/column/group indices
    cID = cell(nGrp,1);
    for i = 1:length(iC)
        [iy,ix] = find(iGrp==i);
        cID{iC(i)} = [cID{iC(i)};[iy,ix,i*ones(length(ix),1)]];
    end
    
    % sorts the ID arrays by column and then by row (for each unique group)
    for i = 1:nGrp
        cID{i} = sortrows(cID{i},[2,1]);
    end
else
    % case is a 1D experiment setup
    iGrp = zeros(size(iMov.flyok));
    [iCol,iRow] = deal(zeros(size(iMov.flyok,2),1));
    for i = 1:size(iGrp,2)
        [iCol(i),~,iRow(i)] = getRegionIndices(iMov,i);
        if iMov.ok(iMov.pInfo.iGrp(iRow(i),iCol(i)))
            iGrp(iMov.flyok(:,i),i) = iMov.pInfo.iGrp(iRow(i),iCol(i));
        end
    end
    
    % memory allocation
    nGrp = length(unique(iGrp(iGrp>0)));
    cID = cell(nGrp,1);
    
    % loops through each group setting the row/column/fly indices
    for i = 1:nGrp
        [iy,ix] = find(iGrp == i);
        cID{i} = [iRow(ix),iCol(ix),iy];
    end
end