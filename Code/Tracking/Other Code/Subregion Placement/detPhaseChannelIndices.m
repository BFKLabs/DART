function iColPh = detPhaseChannelIndices(iMov,ImgF)

% initialisations
xiCh = 1:3;
[iR,iC] = deal(iMov.iR(:)',iMov.iC(:)');
[nFrm,nApp] = deal(length(ImgF),length(iR));

% determines if the sub-region field has been set
if isfield(iMov,'srData') && ~isempty(iMov.srData)
    hasSR = iMov.srData.useSR;
else
    hasSR = false;
end

% determines if the setup has sub-regions
if hasSR
    % if so, then 
    sD = iMov.srData;
    nGrp = cellfun('length',sD.iGrp);
    [iOfs,nCol] = deal([0;cumsum(nGrp(1:end-1))],sum(nGrp));
else
    % if not, then use the region count
    nCol = nApp;
end

% sets the local image stack
IL = cellfun(@(x)(cellfun(@(ir,ic)(x(ir,ic,:)),iR,iC,'un',0)),ImgF,'un',0);
IL = cell2cell(IL);

% memory allocation
iColPh = zeros(nFrm,nCol);
for i = 1:nFrm
    for j = 1:nApp
        % splits the region images by phase
        ILCh = arrayfun(@(x)(IL{i,j}(:,:,x)),xiCh,'un',0);        
        if hasSR
            ILmu = cell2mat(cellfun(@(x)(cellfun(@(y)...
                    (mean(y(x),'omitnan')),ILCh)),sD.iGrpL{j},'un',0));
            [~,iColPh(i,iOfs+(1:nGrp(j)))] = max(ILmu,[],2,'omitnan');
        else
            % case is there is no sub-region split
            ILmu = arrayfun(@(x)(mean(x(:),'omitnan')),ILCh);
            iColPh(i,j) = argMax(ILmu);
        end
    end
end