% --- reduces the region information
function iMov = reduceRegionInfo(iMov)

% determines the number of groups
nApp = length(iMov.pInfo.gName);
if length(iMov.ok) == nApp
    % if the region acceptance flags vector length equals the group count,
    % then exit the function
    return
end

% resets the region information based on experimental setup type
if iMov.is2D
    % case is a 2D expt setup    
    nGrp = max(iMov.pInfo.iGrp(:));
    iok = arrayfun(@(x)(any(iMov.pInfo.iGrp(:)==x)),(1:nGrp)');   
    
elseif detIfCustomGrid(iMov)
    % case is a 1D experiment setup (custom grid)
    gID = iMov.pInfo.gID;
    iok = arrayfun(@(x)(any(cellfun(@(y)(any(y==x)),gID))),1:nApp);
    
else
    % case is a 1D experiment setup (fixed grid)
    iGrp = arr2vec(iMov.pInfo.iGrp');
    iok = iGrp > 0;       

    % updates the other fields
    iMov.pInfo.nGrp = length(iGrp);    
end

% resets the region acceptance flags
iMov.ok = iok;