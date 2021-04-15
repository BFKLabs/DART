% --- creates a bar plot with errorbar (if required)
function [hPlot,xTick] = plotBarError(hAx,Y,Ysem,plotErr,pW,col)

% memory allocation
colErr = 'm';
[nVal,nGrp] = size(Y);    

% sets the default input argument
if (nargin < 4); plotErr = true; end
if (nargin < 5); pW = 0.75; end

if (nargin < 6)
    col = getBarColourScheme(nGrp,colErr); 
elseif (isempty(col))
    col = getBarColourScheme(nGrp,colErr); 
end

% sets the x-offset
dX = ((1:nGrp) - (nGrp+1)/2)*(pW/nGrp);

% creates the bar graphs (+ errorbars) for each group
hPlot = zeros(nGrp,1);
for i = 1:nGrp
    % creates the new bar graph
    xi = (1:nVal) + dX(i);
    hPlot(i) = bar(xi,Y(:,i),pW/nGrp);
    set(hPlot(i),'linestyle','none','tag','hBar','facecolor',col{i})

    % adds the errorbar (if required)
    if (plotErr); addBarError(hAx,xi,Y(:,i),Ysem(:,i),colErr); end
end       

% sets the x-tick indices
xTick = 1:nVal;
set(hAx,'xlim',xTick([1 end]) + 0.5*[-1 1])