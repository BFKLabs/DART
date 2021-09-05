% --- 
function iFrm = getPhaseFrameIndices(iMov,nFrmR,iP)

% sets the phase frame indices (if not provided)
if ~exist('iP','var'); iP = iMov.iPhase; end

% memory allocation
nFrm = ones(size(iP,1),1);

% initialisations
nFrmMax = 25;
nFrmPh = diff(iP,[],2) + 1;
nFrmP = ceil((nFrmMax-2)*(diff(iP,[],2)+1)/iP(end) + 1);

%
isF = nFrmPh == 1;
[i0,i1] = deal((nFrmP < 2) & ~isF,(nFrmP > nFrmR) & ~isF);
[nFrm(i0),nFrm(i1),isF(i0|i1)] = deal(2,nFrmR,true);

% for the remaining phases, split up the 
if any(~isF)
    nFrm(~isF) = min(3,nFrmP(~isF));
end

% sets the final frame index arrays for each phase
iFrm = cell(length(nFrm),1);
for i = 1:length(iFrm)
    iFrm{i} = roundP(linspace(iP(i,1),iP(i,2),nFrm(i)));   
end

% sets the final array
iFrm = cellfun(@(x)(x(:)),iFrm,'un',0);