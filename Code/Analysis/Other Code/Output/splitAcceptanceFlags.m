function fok = splitAcceptanceFlags(snTot)

% initialisations
cID = snTot.cID;
[fok0,pInfo] = deal(snTot.iMov.flyok,snTot.iMov.pInfo);

% resets the acceptance flags 
if snTot.iMov.is2D
    % case is a 2D expt setup
    
    % memory allocation
    sz = [pInfo.nRow,pInfo.nCol];
    fok = false(sz);
    
    % sets the acceptance flags for each group 
    for i = 1:length(cID)
        fok(sub2ind(sz,cID{i}(:,1),cID{i}(:,2))) = fok0{i};
    end
    
else
    % case is a 1D expt setup
    
    % memory allocation
    sz = [pInfo.nFlyMx,pInfo.nRow*pInfo.nCol];
    fok = false(sz);    
    
    % sets the acceptance flags
    X = cell2mat(cID);
    iReg = (X(:,1)-1)*pInfo.nCol + X(:,2);
    fok(sub2ind(sz,X(:,3),iReg)) = true;   
end