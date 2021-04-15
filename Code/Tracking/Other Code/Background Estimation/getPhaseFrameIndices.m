% --- 
function iFrm = getPhaseFrameIndices(iMov,nFrmR,iP)

% sets the phase frame indices (if not provided)
if ~exist('iP','var'); iP = iMov.iPhase; end

% initialisations
nFrmMax = 30;
nFrm = double(1+(iMov.vPhase==1));
nFrmP = (nFrmMax-1)*(diff(iP,[],2)+1)/iP(end);

% adds on frames to each of the phases so that they add to nFrmMax
isAdd = nFrmP > nFrm;
dnFrm = max(0,nFrmMax - sum(nFrm));
nFrm(isAdd) = nFrm(isAdd) + roundP(dnFrm*nFrmP(isAdd)/sum(nFrmP(isAdd)));

% ensures the counts/phase is <= the max phase frame count (nFrmR)
nFrm = max(1,min(roundP(nFrm),nFrmR));

% sets the final frame index arrays for each phase
iFrm = cell(length(nFrm),1);
for i = 1:length(iFrm)
    if i < length(iFrm)
        iFrmNw = roundP(linspace(iP(i,1),iP(i,2),nFrm(i)+1));
        iFrm{i} = iFrmNw(1:end-1);
        
    elseif nFrm(i) == 1
        iFrm{i} = roundP(linspace(iP(i,1),iP(i,2),nFrm(i)+1));
        
    else
        iFrm{i} = roundP(linspace(iP(i,1),iP(i,2),nFrm(i)));
    end
end

%
iFrm = cellfun(@(x)(x(:)),iFrm,'un',0);