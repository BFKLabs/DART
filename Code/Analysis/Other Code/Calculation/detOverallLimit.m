% --- calculates the overall limiting value of an array Y. this limiting
%     value is rounded up to the nearest multiple of 10^floor(log10(yMax))
function yLim = detOverallLimit(Y,varargin)

% calculates the overall maximum value
if isempty(Y)
    yLim = NaN; return
elseif iscell(Y)
    Y = Y(~cellfun('isempty',Y));
    Ymx0 = cellfun(@(x)(max(x(~isinf(x)))),Y,'un',0);
    yLim0 = max(cell2mat(Ymx0));
else
    yLim0 = max(Y(~isinf(Y)));
end

% calculates the multiplier and rounds the max value to the nearest
% multiple of of this multiplier
yMlt = 10^floor(log10(yLim0));
yLim = 0.1*ceil(yLim0/yMlt*10)*yMlt;

% if the maximum equals the overall maximum, then add on another unit
if (yLim == yLim0) && (nargin == 1)
    yLim = yLim + 0.1*yMlt;
end
