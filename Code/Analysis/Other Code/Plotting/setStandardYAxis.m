% --- standardises the axis to a set number of time markers
function yMax = setStandardYAxis(hAx,Y,nTick,Ymx,yOfs)

% sets the default input arguments
if (nargin < 3); nTick = 6; end
if (nargin < 4); Ymx = max(Y(:)); end
if (nargin < 5); yOfs = 0; end

% sets the y-axis increment values
dy = [0.0 0.02 0.025 0.03 0.04 0.05 0.06 0.08 0.1 0.15 0.2 0.25,...
      0.30 0.40 0.5 0.6 0.8 1 2 5 10 20 50 100];

% determines the exponent index
if (isnan(Ymx(end)) || (Ymx(end) == 0)); Ymx(end) = 1; end
Ymx(end) = Ymx(end) - yOfs;
hOfs = floor(log10(Ymx(end)))+1;

% calculates the new tick-markers
YendM = Ymx(end)/((nTick-1)*10^hOfs);
if (any(YendM == dy))
    ii = find(YendM == dy);
else
    ii = find(YendM >= dy,1,'last') + 1;
end
yTick = yOfs + ((0:dy(ii):(nTick-1)*dy(ii)))*10^hOfs;

% resets the ticklabels
set(hAx,'ytick',yTick,'ylim',yTick([1 end]))
if (yOfs ~= 0)
    yTickLbl = cellfun(@(x)(num2str(x)),num2cell(yTick-yOfs),'un',0);
    set(hAx,'yticklabel',yTickLbl);
end
yMax = yTick(end);
