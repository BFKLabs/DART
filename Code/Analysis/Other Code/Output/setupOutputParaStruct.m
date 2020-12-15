% --- initialises the output parameter struct
function oP = setupOutputParaStruct(snTot,sepDay,sepExp,metStats,grpComb)

% sets the day separation flag (based on the experiment duration)
if (nargin < 2)
    % determines if any of the experiment durations are greater than 1 day
    sepDay = any(detExptDayDuration(snTot) > 1); 
end

% sets the experiment separation flag (based on the experiment count)
if (nargin < 3)
    % if more than one experiment, then allow separation by experiment
    sepExp = length(snTot) > 1;
end

% sets the metric statistic calculations flag
if (nargin < 4); metStats = true; end
if (nargin < 5); grpComb = false; end

% memory allocation for the output parameter struct
oP = struct('xVar',[],'yVar',[],'sepDay',sepDay,'sepGrp',false,...
            'sepExp',sepExp,'metStats',metStats,'grpComb',grpComb);