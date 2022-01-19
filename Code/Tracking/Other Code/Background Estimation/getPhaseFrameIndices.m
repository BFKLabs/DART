% --- 
function iFrm = getPhaseFrameIndices(iMov,nFrmR,iP)

% sets the phase frame indices (if not provided)
if ~exist('iP','var'); iP = iMov.iPhase; end

% memory allocation
nFrm = NaN(size(iP,1),1);

% initialisations
dFrm = 300;
nFrmSmall = 25;
nFrmPh = diff(iP,[],2) + 1;

% sets the frame counts for the single frame/small phases
isSingle = nFrmPh == 1;
isSmall = (nFrmPh <= nFrmSmall) & ~isSingle;
[nFrm(isSingle),nFrm(isSmall)] = deal(1,2);

% sets the frame counts for the other phases
isOther = ~(isSmall | isSingle);
nFrm(isOther) = min(nFrmR,2+ceil(nFrmPh(isOther)/dFrm));

% sets the final frame index arrays for each phase
iFrm = cell(length(nFrm),1);
for i = 1:length(iFrm)
    iFrm{i} = roundP(linspace(iP(i,1),iP(i,2),nFrm(i)));   
end

% sets the final array
iFrm = cellfun(@(x)(x(:)),iFrm,'un',0);
