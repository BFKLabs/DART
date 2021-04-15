% --- 
function combG = getCombSubRegionIndices(iMov,rtP,varargin)

% sets the indices of the valid sub-regions
combG = rtP.combG;
[aok,ind] = deal(find(iMov.ok),combG.ind);

% only initialise the channel to group indices if using stimuli
if (~isempty(rtP.Stim))
    if (~strcmp(rtP.Stim.cType,'Ch2App')); ind(:) = NaN; end
end

% determines if any of the sub-regions have been combined
isG = ~isnan(ind);
if (all(~isG))
    % no groupings, so return the valid sub-region indices
    iGrp = aok;
else
    % sets the indices of the non-grouped indices
    isS = find(~isG);
    ind(isS) = max(ind(isG)) + (1:length(isS));
        
    % determines the sub-region groupings
    a = num2cell(1:max(ind))';
    iGrp = combineNumericCells(cellfun(@(x)(aok(ind==x)),a,'un',0))';    
    
    % if there are no groupings, then return the original indices
    if (size(iGrp,2) == 1)
        iGrp = aok;
    end
end

%
if (nargin == 2)
    % sets the group order
    [combG.iGrp,a] = deal(iGrp,iGrp');
    combG.iGrpOrd = a(~isnan(a(:)));
    combG.nGrp = sum(~isnan(combG.iGrp),2);
else
    combG = iGrp;
end