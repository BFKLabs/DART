% --- groups the acceptance flags for a given experiment
function fok = groupAcceptFlags(snTot,iApp)

% field retrieval
[iMov,cID] = deal(snTot.iMov,snTot.cID);
[fok0,pInfo] = deal(iMov.flyok,iMov.pInfo);
sz = size(fok0);

% memory allocation
if iscell(fok0)
    fok = fok0;
    return
else
    nGrp = length(cID);
    fok = cell(1,nGrp);
end

% loops through each group type setting the acceptance flags
for i = 1:nGrp
    if iMov.is2D
        % case is a 2D expt setup
        fok{i} = fok0(sub2ind(sz,cID{i}(:,1),cID{i}(:,2)));
    else
        % case is a 1D expt setup
        iReg = (cID{i}(:,1)-1)*pInfo.nCol + cID{i}(:,2);
        fok{i} = fok0(sub2ind(sz,cID{i}(:,3),iReg));
    end
end

% returns the flags for a specific region (if provided)
if exist('iApp','var')
    fok = fok{iApp};
end