function snTot = splitAcceptanceFlags(snTot)

% initialisations
cID = snTot.cID;
isMT = detMltTrkStatus(snTot.iMov);
[fok0,pInfo] = deal(snTot.iMov.flyok,snTot.iMov.pInfo);
% gName0 = pInfo.gName;

% resets the acceptance flags 
if isMT
    % case is multi-tracking experiment

    % memory allocation
    fok = false(size(pInfo.nFly));
    
    % sets the acceptance flags for each group 
    for i = 1:length(cID)
        if ~isempty(cID{i})
            [iA,~,iC] = unique(cID{i}(:,1));
            for j = 1:length(iA)
                isM = find(iC == j,1,'first');
                [iCL,iRL] = ind2sub(size(fok),iA(j));
                fok(iRL,iCL) = fok0{i}(isM);
            end
        end
    end
    
elseif snTot.iMov.is2D
    % case is a 2D expt setup
    
    % memory allocation
    sz = [pInfo.nRow,pInfo.nCol];
    fok = false(sz);
    
    % sets the acceptance flags for each group 
    for i = 1:length(cID)
        if ~isempty(cID{i})
            % updates the acceptance flags
            indG = sub2ind(sz,cID{i}(:,1),cID{i}(:,2));
            fok(indG) = fok0{i};
        end
    end   
    
else    
    % memory allocation
    isCust = detIfCustomGrid(snTot.iMov);
    nFlyMx = max(cellfun('length',snTot.iMov.iRT(:)));
    sz = [nFlyMx,pInfo.nRow*pInfo.nCol];
    [fok,ok] = deal(false(sz),false(sz(2),1));
    
    % calculates the linear indices
    for i = 1:length(cID)
        if ~isempty(cID{i})
            % updates the sub-region flags
            iReg = (cID{i}(:,1)-1)*pInfo.nCol + cID{i}(:,2);
            indG = sub2ind(sz,cID{i}(:,3),iReg);
            fok(indG) = true;
            
            % updates the region group index (fixed grid only)
            if ~isCust
                indU = unique(iReg(:));
                pInfo.iGrp(indU) = i;
            end

            % updates the region flag and acceptance values           
            ok(unique(iReg(fok(indG)))) = true;                      
        end
    end
    
end

% updates the flags within the sub-region data struct
[snTot.iMov.flyok,snTot.iMov.pInfo] = deal(fok,pInfo);
if exist('ok','var'); snTot.iMov.ok = ok; end