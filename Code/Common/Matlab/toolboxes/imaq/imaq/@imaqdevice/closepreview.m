function closepreview(obj)
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

% Error checking.
if ~isa(obj, 'imaqdevice'),
    error(message('imaq:closepreview:invalidType'));
elseif ~all(isvalid(obj)),
    error(message('imaq:closepreview:invalidOBJ'));
end

% Access the internal UDD object.
uddobj = imaqgate('privateGetField', obj, 'uddobject');

% Keep tabs on when to error (OBJ is 1x1) or
% when to warn (OBJ is a vector).
alreadyWarned = false;
isSingleton = (length(uddobj)==1);
for index=1:length(uddobj)
    try
        % Close internal preview window handle.
        closepreview( uddobj(index) );

        % TODO: Consider moving this into the engine.
        handles = get(uddobj(index), 'ZZZPreviewWindowHandles');
        if ~isempty(handles) && handles.isDefaultWindow
            % Close HG window since it's ours.
            delete(handles.Figure);
        end
        set(uddobj(index), 'ZZZUpdatePreviewFcn', '');
        set(uddobj(index), 'ZZZUpdatePreviewStatusFcn', '');
        set(uddobj(index), 'ZZZPreviewWindowHandles', []);
    catch exception
        % Error if we're dealing with a 1x1 object, otherwise warn.
        if isSingleton
            throw(exception);
        elseif ~alreadyWarned
            warnState = warning('off', 'backtrace');
            oc = onCleanup(@()warning(warnState));
            warning(message('imaq:closepreview:closeFailed'));
            clear('oc');
            alreadyWarned = true;
        end
    end
end
