% --- sets the binned time array
function [Tnw,indB] = setBinnedTimeArray(Ttot,indB,tBin)

% initialisations
Tnw = NaN(length(indB),1);
jj = cellfun('length',indB) > 1;

% calculates thAe time bins for 
Tnw(jj) = cellfun(@(x)(roundP(median(Ttot(x)),tBin/2)),indB(jj));

% removes any infeasible time bins
isN = ~isnan(Tnw);
[Tnw,indB] = deal(Tnw(isN),indB(isN));