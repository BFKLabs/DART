% --- sets up the binned time array for the total time array, Ttot, and the
%     bin indices cell array, indB --- %
function T = setupBinnedTimeArray(Ttot,indB)

% memory allocation
[jj,T] = deal(cellfun(@length,indB) > 1,NaN(length(indB),1));

% allocates memory for the temporary data/time plot arrays
T(jj) = cellfun(@(x)(nanmean(Ttot(x))),indB(jj));