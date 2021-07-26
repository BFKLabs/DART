function gName = separateMultiExptGroupNames(snTot)

% resets the group names    
cID0 = snTot.cID;  
ii = ~cellfun(@isempty,cID0);
xiC = num2cell(1:length(ii))';
pInfo = snTot.iMov.pInfo;

% sets up the total configuration index array
if snTot.iMov.is2D
    % memory allocation
    gName = repmat({'* REJECTED *'},pInfo.nGrp,1);

    % sets the original/final group index array
    cIDT = cell2mat(cellfun(@(x,id)([id(:,3),...
                x*ones(size(id,1),1)]),xiC(ii),cID0(ii),'un',0));        
else
    % memory allocation
    gName = repmat({'* REJECTED *'},pInfo.nRow*pInfo.nCol,1);

    % sets the original/final group index array
    A = cell2mat(cellfun(@(x,id)([id(:,1:2),...
                x*ones(size(id,1),1)]),xiC(ii),cID0(ii),'un',0));
    iApp = (A(:,1)-1)*snTot.iMov.pInfo.nCol + A(:,2); 
    cIDT = [iApp,A(:,3)];
end

% sets the group names based on the unique configuration index rows
indF = unique(cIDT,'rows','stable');
for j = 1:size(indF,1)
    gName{indF(j,1)} = pInfo.gName{indF(j,2)};
end    