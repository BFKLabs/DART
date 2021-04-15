% --- sets up the waitbar figure index arrays
function [iW,isW] = setupWaitbarArrays(N,nW)

% sets the default input arguments
if (nargin == 1); nW = 21; end

% creates the waitbar figure index arrays
[iW,isW] = deal(roundP(linspace(0,N,nW)),false(nW,1));