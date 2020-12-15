function closepreview(in)
%CLOSEPREVIEW Close Video Preview window.
%
%    CLOSEPREVIEW(OBJ) stops the image acquisition object OBJ from
%    previewing and, if the default Video Preview window was used, closes
%    the window.
%
%    CLOSEPREVIEW stops all image acquisition objects from previewing 
%    and, for all image acquisition objects that used the default Video
%    Preview window, closes the windows.
%
%    Note: If the preview window was created with a user specified image
%    object handle as the target, CLOSEPREVIEW does not close the figure 
%    window.
%
%    See also IMAQHELP, IMAQDEVICE/PREVIEW, IMAQDEVICE/STOPPREVIEW.

%    CP 9-01-01
%    Copyright 2001-2010 The MathWorks, Inc.

% Make sure that the only input argument allowed is [].
if nargin==1,
    if ~isempty(in)
        error(message('imaq:closepreview:invalidType'));
    else
        % >> closepreview(imaqfind) % where imaqfind returns []
        return;
    end
end

% Close all preview windows.
closepreview(imaqfind);