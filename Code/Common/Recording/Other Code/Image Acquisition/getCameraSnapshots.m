% --- retrieves the set number of frames from the camera
function Img = getCameraSnapshots(objIMAQ,Nframe,h)

% parameters & memory allocation
[wP,Img] = deal(1,cell(Nframe,1));

% sets up the waitbar figure
if (nargin == 2)
    wStr = {'Reading Image Frames'};
    h = waitbarFig(wStr,'Reading Video Frames');
else
    wStr = getappdata(h,'wStr');
end

% reads the required frames from the camera
for i = 1:Nframe
    % updates the waitbar figure
    if (waitbarFig(1,sprintf('%s (%i of %i)',wStr{1},i,Nframe),i/Nframe,h))
        Img = [];
        return
    end
    
    % reads the new frame from the camera
    Img{i} = getsnapshot(objIMAQ);
    if (i < Nframe)
        % if not the final frame, then pause for wP seconds
        pause(wP);
    end
end

% closes the waitbar figure
if (nargin == 2); close(h); end