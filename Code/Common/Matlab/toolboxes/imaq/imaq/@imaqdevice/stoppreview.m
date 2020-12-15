function stoppreview(obj)
%STOPPREVIEW Stops previewing video data in Video Preview window.
% 
%    STOPPREVIEW(OBJ) stops the previewing of video data from the
%    image acquisition object OBJ. 
%    
%    To restart previewing, call PREVIEW again.
%
%    Example
%
%    % Create a video input object and open a Video Preview window.
%    vid = videoinput('winvideo',1);
%    preview(vid)
%    
%    % Stop previewing video data in the Video Preview window.
%    stoppreview(vid)
%
%    % Restart previewing in the Video Preview window.
%    preview(vid)
%
%    See also IMAQHELP, IMAQDEVICE/CLOSEPREVIEW, IMAQDEVICE/PREVIEW.

%    CP 10-15-04
%    Copyright 2001-2010 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'imaqdevice'),
    error(message('imaq:stoppreview:invalidType'));
elseif ~all(isvalid(obj)),
    error(message('imaq:stoppreview:invalidOBJ'));
end

% Access the internal UDD object.
uddobj = imaqgate('privateGetField', obj, 'uddobject');

% Keep tabs on when to error (OBJ is 1x1) or 
% when to warn (OBJ is a vector).
alreadyWarned = false;
isSingleton = (length(uddobj)==1);
for index=1:length(uddobj)
    try
        % Stop the preview windows.
        stoppreview( uddobj(index) );
    catch exception
        % Error if we're dealing with a 1x1 object, otherwise warn.
        if isSingleton
            throw(exception);
        elseif ~alreadyWarned
            warnState = warning('off', 'backtrace');
            oc = onCleanup(@()warning(warnState));
            warning(message('imaq:stoppreview:stopFailed'));
            clear('oc');
            alreadyWarned = true;
        end
    end
end
