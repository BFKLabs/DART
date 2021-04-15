% --- determines if an experiment is short depending on the duration(s)
function isShort = detIfShortExpt(T,Tmin)

% sets the default input argument value 
if (nargin == 1); Tmin = 12; end

% determines if the experiment are short
Tf = cellfun(@(x)(convertTime(x{end}(end),'sec','hrs')),T);
isShort = all(Tf < Tmin);