% --- retrieves the frame stack size
function NN = getFrameStackSize()

% global variables
global frmSz

% retrieves the memory parameters
try
    % determines the frame stack size based on the video resolution
    mP = memory;
    if (prod(frmSz*3*8) > mP.MaxPossibleArrayBytes)
        % frame size is large, so use smaller frame stack size
        NN = 25;    
    else
        % otherwise, use a larger frame stack size
        NN = 50;
    end
catch
    % otherwise, use a heuristic value for the frame size
    NN = 25*(1+(max(frmSz)>1500));
end