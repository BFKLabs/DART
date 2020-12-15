function initdistgrid(hAxes)
%INITDISTGRID initialize distortion plot grid
%   Initialize the distortion grid so that it uses a light gray grid.
%   Additionally make room for markers.
%   
%   This function is for internal use only. It may be removed in the future.
   
%   Copyright 2013 The MathWorks, Inc.

% bound plot by y limit; give 10 extra dB for fundamental marker.
yTick = get(hAxes,'YTick');
if numel(yTick>1)
  yNew = yTick(end) + 10;
  yLim = get(hAxes,'YLim');
  set(hAxes,'YLim',[yLim(1) yNew]);
end

% Ensure axes limits are properly cached for zoom/unzoom
resetplotview(hAxes,'SaveCurrentView');  

% turn on border
set(hAxes,'Box','on');

% get axes ticks and limits
xTick = get(hAxes,'XTick');
yTick = get(hAxes,'YTick');
xLim = get(hAxes,'XLim');
yLim = get(hAxes,'YLim');
nX = numel(xTick);
nY = numel(yTick);

% draw horizontal grid lines that aren't on the border
for i=1:nY
  if ~any(yTick(i)==yLim)
    line(xLim, [yTick(i) yTick(i)],'Color',[.75 .75 .75]);
  end
end

% draw vertical grid lines that aren't on the border
for i=1:nX
  if ~any(xTick(i)==xLim)
    line([xTick(i) xTick(i)],yLim,'Color',[.75 .75 .75]);
  end
end