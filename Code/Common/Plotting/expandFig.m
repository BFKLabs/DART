% function that expands a figure to full screen
function hf = expandFig(h,pPos)

% retrieves the maximum screen dimensions
if (nargin == 1)
    figPos = getMaxScreenDim();
else
    figPos = getMaxScreenDim(pPos);
end
    
% resets the figure position
set(h,'position',figPos,'PaperPositionMode','auto','color',[1 1 1],...
      'tag','nwPlot'); 
hf = gcf;

