% --- 
function iFrm = getPhaseFrameIndices(iMov,nFrmR,iP)

% sets the phase frame indices (if not provided)
if ~exist('iP','var'); iP = iMov.iPhase; end

% initialisations
nFrmMax = 25;
nFrm = (nFrmMax-1)*(diff(iP,[],2)+1)/iP(end);

% ensures all frame counts < 1 are set to 1 (remove the frame contributions
% from all the other phases)
ii = nFrm < 1;
[nFrm(~ii),nFrm(ii)] = deal(nFrm(~ii)-sum(1-nFrm(ii))/sum(~ii),1);

% loop through all the phases until the frame counts are all integers
while sum(ii) < (length(nFrm)-1)
    % determines the index of the next phase
    iNw = find(nFrm == min(nFrm(mod(nFrm,1) > 0)));    
    
    % determines whether the frame 
    nFrmM = mod(nFrm(iNw),1);
    if nFrmM >= 0.5
        [dnFrm,nFrm(iNw)] = deal(1-nFrmM,ceil(nFrm(iNw)));
    else
        [dnFrm,nFrm(iNw)] = deal(-nFrmM,floor(nFrm(iNw)));
    end
    
    % resets the found flag and update the counts of the other phases
    ii(iNw) = true;
    nFrm(~ii) = nFrm(~ii)-(dnFrm/sum(~ii));    
end

% ensures the counts/phase is <= the max phase frame count (nFrmR)
nFrm = min(roundP(nFrm),nFrmR);

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