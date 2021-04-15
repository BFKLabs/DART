% --- returns the statistic metric variable from an index
function [vName,vNameF] = ind2varStat(ind,varargin)

% returns the variable name string based on the index 
switch (ind)
    case (1) % case is the mean
        [vName,vNameF] = deal('mn','Mean');
    case (2) % case is the median
        [vName,vNameF] = deal('md','Median');        
    case (3) % case is the lower quartile
        [vName,vNameF] = deal('lq','L. Quartile');        
    case (4) % case is the upper quartile
        [vName,vNameF] = deal('uq','U. Quartile');        
    case (5) % case is the range
        [vName,vNameF] = deal('rng','Range');        
    case (6) % case is the confidence interval
        [vName,vNameF] = deal('ci','Conf. Interval');        
    case (7) % case is the standard deviation
        [vName,vNameF] = deal('sd','Std. Deviation');        
    case (8) % case is the standard error mean
        [vName,vNameF] = deal('sem','Std. Err. Mean');        
    case (9) % case is the minimum
        [vName,vNameF] = deal('min','Minimum');        
    case (10) % case is the maximum
        [vName,vNameF] = deal('max','Maximum');        
    case (11) % case is the maximum
        [vName,vNameF] = deal('N','N-Value');             
end

% resets the variable strings (depending on the number of inputs)
if (nargin == 2); vName = vNameF; end