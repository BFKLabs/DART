% --- determines if the current mouse position is over the plot axes
function isOver = isOverAxes(mPos,axPosXF,axPosYF)

% global variables
global axPosX axPosY

% sets the default input arguments
if ~exist('axPosXF','var')
    [axPosXF,axPosYF] = deal(axPosX,axPosY);
end

% determines if the mouse position is over the signal setup plot axes
isOver = prod(sign(axPosXF - mPos(1))) == -1 && ...
         prod(sign(axPosYF - mPos(2))) == -1;