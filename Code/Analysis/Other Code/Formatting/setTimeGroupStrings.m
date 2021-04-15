% --- creates the time group strings
function Tgrp = setTimeGroupStrings(nGrp,Tgrp0,useZG)

%
if (nargin < 3); useZG = false; end

if (nGrp == 1)
    % only one group, so set string to all times
    Tgrp = {'All Times'};
else
    % more than one group, so set for each group
    [dT,b] = deal(24/nGrp,clock);
    if (useZG)            
        Tvec = mod(0:dT:24,24);
        Tgrp = cellfun(@(x,y)(sprintf('%i-%i',x,y)),...
                    num2cell(Tvec(1:end-1)),num2cell(Tvec(2:end)),'un',0);
    else
        Tvec = cellfun(@(x)(datestr([b(1:2),sec2vec(convertTime(...
                    Tgrp0+(x-1)*dT,'hrs','sec'))],'HH PM')),...
                    num2cell(1:nGrp)','un',0);
        Tgrp = cellfun(@(x,y)(sprintf('%s -%s',x,y)),...
                    Tvec,Tvec(circshift((1:nGrp)',-1)),'un',0);                                  
    end
end