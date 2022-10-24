% --- initialises the output parameter struct
function oP = setupOutputParaStruct(snTot,sepDay,sepExp,metStats,grpComb)

% sets the day separation flag (based on the experiment duration)
if ~exist('sepDay','var')
    % determines if any of the experiment durations are greater than 1 day
    sepDay = any(detExptDayDuration(snTot) > 1); 
end

% sets the experiment separation flag (based on the experiment count)
if ~exist('sepExp','var')
    % if more than one experiment, then allow separation by experiment
    sepExp = length(snTot) > 1;
end

% sets the metric statistic calculations flag
if ~exist('metStats','var'); metStats = true; end
if ~exist('grpComb','var'); grpComb = false; end

% memory allocation for the output parameter struct
oP = struct('xVar',[],'yVar',[],'sepDay',sepDay,'sepGrp',false,...
            'sepExp',sepExp,'metStats',metStats,'grpComb',grpComb);