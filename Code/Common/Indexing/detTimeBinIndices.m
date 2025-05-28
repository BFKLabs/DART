% --- determines the indices within the time array, T, that have been
%     binned in durations of tBin seconds
function indB = detTimeBinIndices(T,tBin,varargin)

% determines the bin indices for each time point
if (nargin == 2)
    iBin = floor((T-T(1))/tBin) + 1;
else
    iBin = floor(T/tBin) + 1;
    iBin = (iBin - min(iBin)) + 1;
end
    
% memory allocation
[ii,idBin] = unique(iBin);
indB = cell(ii(end),1); 

% sets the
A = num2cell([[1;idBin],[(idBin-1);length(T)]],2);
indB([1;ii]) = cellfun(@(x)(x(1):x(min(length(x),2))),A,'un',0);

if length(indB) > 1
    if (diff(cellfun(@(x)(T(x(end))),indB(end-1:end))) < 3*tBin/4)
        indB = indB(1:end-1);
    end
end