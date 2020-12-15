% --- expands the axes limits slightly to include edge text labels
function expandAxesLim(hAx,varargin)

% initialisations
[xLim,pW] = deal(get(hAx,'xlim'),1e-4);

% resets the axes limits
set(hAx,'xlim',xLim+pW*diff(xLim)*[-1 1])