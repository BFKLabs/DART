% --- sets the colour channel map
function I = setColourChannelImage(iMov,I,iPh)

% initialisations
iColCh = iMov.iColPh(iPh,:);
[xiCh,sz] = deal(1:3,size(I{1}(:,:,1)));
[iR,iC] = deal(iMov.iR(:)',iMov.iC(:)');
[nApp,nFrm] = deal(length(iMov.iR),length(I));

% determines if the sub-region field has been set
if isfield(iMov,'srData') && ~isempty(iMov.srData)
    hasSR = iMov.srData.useSR;
else
    hasSR = false;
end

%
for i = 1:nFrm
    % splits the image into the separate colour channels
    [I0,I{i}] = deal(I{i},zeros(sz));
    ICh = arrayfun(@(x)(I0(:,:,x)),xiCh,'un',0);
    
    %
    for j = 1:nApp
        % determine if there are split regions
        if hasSR
            % determines if the setup has sub-regions
            if isequal([i,j],[1,1])
                sD = iMov.srData;
                nGrp = cellfun(@length,sD.iGrp);
                iOfs = [0;cumsum(nGrp(1:end-1))];
            end            
            
            % case is there are no split-regions
            for k = 1:length(sD.iGrp{j})
                iGrpS = sD.iGrp{j}{k};
                kk = iColCh(iOfs(j)+k);
                I{i}(iGrpS) = ICh{kk}(iGrpS);
            end
        else
            % case is there are no split-regions
            k = iColCh(j);
            I{i}(iR{j},iC{j}) = ICh{k}(iR{j},iC{j});
        end
    end
end