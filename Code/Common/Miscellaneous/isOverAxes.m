% --- determines if the current mouse position is over the plot axes
function isOver = isOverAxes(mPos)

% global variables
global axPosX axPosY

% determines if the mouse position is over the signal setup plot axes
isOver = prod(sign(axPosX - mPos(1))) == -1 && ...
         prod(sign(axPosY - mPos(2))) == -1;