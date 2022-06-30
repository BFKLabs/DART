function snTot = splitAcceptanceFlags(snTot)

% initialisations
cID = snTot.cID;
isMT = detMltTrkStatus(snTot.iMov);
[fok0,pInfo] = deal(snTot.iMov.flyok,snTot.iMov.pInfo);
gName0 = pInfo.gName;

% resets the acceptance flags 
if isMT
    % case is multi-tracking experiment

    % memory allocation
    fok = arrayfun(@(x)(false(x,1)),pInfo.nFly,'un',0);    
    
    % sets the acceptance flags for each group 
    for i = 1:length(cID)
        if ~isempty(cID{i})
            [iA,~,iC] = unique(cID{i}(:,1));
            for j = 1:length(iA)
                [isM,k] = deal(iC==j,iA(j));
                fok{k}(cID{i}(isM,2)) = true;
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
    % case is a 1D expt setup
    
    % memory allocation    
    sz = [pInfo.nFlyMx,pInfo.nRow*pInfo.nCol];
    [fok,ok] = deal(false(sz),false(sz(2),1));    
    
    % calculates the linear indices
    for i = 1:length(cID)
        if ~isempty(cID{i})
            % updates the sub-region flags
            iReg = (cID{i}(:,1)-1)*pInfo.nCol + cID{i}(:,2);
            indG = sub2ind(sz,cID{i}(:,3),iReg);
            fok(indG) = true;

            % updates the region flag and names             
            indU = unique(iReg(:));
%             [pInfo.gName(indU),pInfo.iGrp(indU)] = deal(gName0(i),i);
            pInfo.iGrp(indU) = i;
            ok(unique(iReg(fok(indG)))) = true;
        end
    end
end

% updates the flags within the sub-region data struct
[snTot.iMov.flyok,snTot.iMov.pInfo] = deal(fok,pInfo);
if exist('ok','var'); snTot.iMov.ok = ok; end