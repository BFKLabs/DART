function gID = setup1DGroupFlags(iMov)

% field retrieval and memory allocation
[iGrp,nFly] = deal(iMov.pInfo.iGrp,iMov.pInfo.nFly);

% sets the group ID flags
gID = arrayfun(@(x,n)(x*ones(n,1)),iGrp,nFly,'un',0);

% removes any rejeced region/flies
for i = 1:size(iMov.flyok,2)
    % determines the row/column index from the global index
    [iRow,iCol] = ind2sub(size(gID),i); 
    
    if ~iMov.ok(i)
        % if the region is rejected, then reset group ID flags to zero
        gID{iRow,iCol}(:) = 0;        
        
    else
        % otherwise, remove any rejected regions
        fOK = iMov.flyok(1:nFly(iRow,iCol));    
        gID{iRow,iCol}(~fOK) = 0;
    end
end