% --- retrieves the downsampled row indices
function indDS = getDownSampledRowIndices(iMov,iApp)

% retrieves the downsampling rate
nDS = getDownSampleRate(iMov);
isCol = isColGroup(iMov);

% sets the new indices depending on the downsampled rate
if (nDS == 1)
    % if no downsampling, then return the original indices
    if (isCol)
        indDS = iMov.iCT{iApp};
    else
        indDS = iMov.iRT{iApp};
    end
else
    % memory allocation
    if (isCol)
        ii = iMov.iCT{iApp};        
    else
        ii = iMov.iRT{iApp};
    end    
    
    % memory allocation
    [nTube,nR] = deal(length(ii),ii{end}(end));
    [indL,ind,indDS] = deal(1:nDS:nR,zeros(nR,1),cell(nTube,1));
    
    % sets the index array
    for i = 1:nTube
        ind(ii{i}) = i; 
        indDS{i} = find(ind(indL) == i);
    end
end

% ensures the indices are row vectors
indDS = cellfun(@(x)(x(:)),indDS,'un',0);