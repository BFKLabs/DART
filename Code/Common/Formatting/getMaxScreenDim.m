% --- retrieves the maximum screen dimensions --- %
function [figPos,figPosMx] = getMaxScreenDim(pPos)

% sets the screen dimensions and offset
[del,scrSz] = deal(50,getPanelPosPix(0,'Pixels','ScreenSize'));    
if ispc
    % case is OS is PC
    figPos = [scrSz(1) del scrSz(3) (scrSz(4)-3*del)];
else
    % case is OS is Mac
    figPos = [scrSz(1) del scrSz(3) (scrSz(4)-2*del)];
end

% makes a copy of the absolute max position
figPosMx = figPos;

% determines the limiting dimension and rescales (if position array is
% given for relative size comparison)
if (nargin == 1)
    [~,imx] = deal(pPos(3:4)./figPos(3:4)); 
    if (imx == 1)
        % width is limiting dimension
        figPos(4) = figPos(3)*(pPos(4)/pPos(3));
    else
        % height is limiting dimension
        figPos(3) = figPos(4)*(pPos(3)/pPos(4));
    end
end

% ensures the positions are integers
[figPos,figPosMx] = deal(roundP(figPos,1),roundP(figPosMx,1));