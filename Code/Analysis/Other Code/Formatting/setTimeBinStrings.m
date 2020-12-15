% --- sets the time bin strings
function Tgrp = setTimeBinStrings(tBin,nGrp,varargin)

% sets the strings based on the number of inputs
if (nargin == 2)
    % sets the bin time strings only
    Tgrp = cellfun(@(x)(sprintf('%i-%i',(x-1)*tBin+1,x*tBin)),...
                        num2cell(1:nGrp)','un',0);                             
else
    % sets the full time bin strings
    Tgrp = cellfun(@(x)(sprintf('Time Bin = (%i-%i min)',(x-1)*tBin+1,x*tBin)),...
                        num2cell(1:nGrp)','un',0);                                 
end