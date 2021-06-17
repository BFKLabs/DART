% --- resets the sub-regions by their unique names
function snTot = resetUniqueSubRegions(snTot)

% retrieves the sub-structs from the main data struct
iMov = snTot.iMov;

% determine the groupings of the sub-regions
[gName,~,iC] = unique(iMov.pInfo.gName); 
if length(gName) == length(iMov.pInfo.gName)
    % if there is no grouping, then exit the function
    return
else    
    % determines the grouping indices
    indG = arrayfun(@(x)(find(iC == x)),1:length(gName),'un',0);
    
    % sorts the sub-groups by their original order
    [~,iSort] = sort(cellfun(@(x)(x(1)),indG));    
    [iMov.pInfo.gName,indG] = deal(gName(iSort),indG(iSort));   
end

% initialisations
[nTube,hasPhi] = deal(getSRCount(iMov),isfield(snTot,'Phi'));
[nApp,Px0,Py0] = deal(length(gName),snTot.Px,snTot.Py);

% memory allocations
[snTot.Px,snTot.Py] = deal(cell(nApp,1));
iMov.nTubeR = cellfun(@(x)(sum(nTube(x))),indG);
[iMov.dTube,iMov.nRow,iMov.nCol] = deal(true,1,nApp);
[iMov.ok,iMov.flyok] = deal(true(nApp,1),false(max(iMov.nTubeR),nApp));
[iR,iC,iRT,iCT,xTube,yTube,Status] = deal(cell(1,nApp));
if (hasPhi); [Phi,AxR] = deal(cell(1,nApp)); end

% updates the fields for each of the unique sub-regions
for i = 1:nApp    
    % reset the x positional values 
    if ~isempty(Px0)
        snTot.Px{i} = cell2mat(reshape(Px0(indG{i}),1,length(indG{i})));
    end
    % reset the y positional values 
    if ~isempty(Py0)      
        snTot.Py{i} = cell2mat(reshape(Py0(indG{i}),1,length(indG{i})));
    end
    
    % resets the acceptance/rejection flags
    b = num2cell(nTube(indG{i}));
    a = cellfun(@(x,y)(x(1:y)),num2cell(iMov.flyok(:,indG{i}),1),b(:)','un',0);
    iMov.flyok(1:sum(nTube(indG{i})),i) = cell2mat(a(:));    
    
    % resets the row/column global/local indices
    iRTmp = iMov.iRT(indG{i});
    iRT{i} = cell2cell(iRTmp(:));    
    if (iscell(iMov.iCT{indG{i}(1)}))
        aTmp = iMov.iR(indG{i}); iR{i} = cell2cell(aTmp(:));
        bTmp = iMov.iC(indG{i}); iC{i} = cell2cell(bTmp(:));
        cTmp = iMov.iCT(indG{i}); iCT{i} = cell2cell(cTmp(:));
    else
        iCT{i} = iMov.iCT(indG{i})';
        [iR{i},iC{i}] = deal(iMov.iR(indG{i})',iMov.iC(indG{i})');    
    end
    
    % resets the x/y-tube coordinates
    xTube{i} = cell2mat(iMov.xTube(indG{i})');
    yTube{i} = cell2mat(iMov.yTube(indG{i})');
    Status{i} = cell2mat(iMov.Status(indG{i})');
    
    % resets the orientation angles (if set)
    if hasPhi
        Phi{i} = cell2mat(reshape(snTot.Phi(indG{i}),1,length(indG{i})));
        AxR{i} = cell2mat(reshape(snTot.AxR(indG{i}),1,length(indG{i})));
    end
end

% resets the orientation angles
if hasPhi; [snTot.Phi,snTot.AxR] = deal(Phi,AxR); end

% resets the sub-region fields
[iMov.iR,iMov.iC,iMov.iRT,iMov.iCT] = deal(iR,iC,iRT,iCT);
[iMov.xTube,iMov.yTube,iMov.Status] = deal(xTube,yTube,Status);

% resets the sub-structs from the main data struct
snTot.iMov = iMov;