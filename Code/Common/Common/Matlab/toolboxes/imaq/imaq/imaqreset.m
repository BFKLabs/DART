function imaqreset
%IMAQRESET Disconnect and delete all image acquisition objects.
%
%    IMAQRESET deletes any image acquisition objects existing in 
%    memory as well as unloads all adaptors loaded by the toolbox. As
%    a result, the image acquisition hardware is reset.
%
%    IMAQRESET is the image acquisition command that returns MATLAB to 
%    the known state of having no image acquisition objects and no 
%    loaded image acquisition adaptors.
%
%    IMAQRESET will also force the toolbox to search for new hardware 
%    that may have been installed while MATLAB was running.
%
%    IMAQRESET should not be called from any of the callbacks of a
%    VIDEOINPUT object such as the StartFcn or FramesAcquiredFcn.
%
%    See also IMAQHELP, IMAQDEVICE/DELETE.

%    CP 9-01-01
%    Copyright 2001-2013 The MathWorks, Inc.
try

    % TODO Consider moving into engine once HG calls are moved inside.
    closepreview;
    if ~isdeployed() && usejava('jvm')
        iatbrowser.preRefreshHardwareList;
    end
    
    srcs = imaqfind('Type','videosource');
     
    imaqmex('imaqreset');
    % Flush event queue of callbacks into the toolbox preferences
    % manager so that they do not fire later at an inappropriate
    % time.
    drawnow;
    % Videsource objects need to be explicitly deleted now as they are noy
    % imaqchild objects any more
    if ~isempty(srcs)
        cellfun(@(src) src.privateDelete(), srcs);
    end
    builtin('clear','imaqmex');
    try
        % clear the ToolboxPreferencesManager so that the next time
        % it is called upon it will reload the toolbox preferences 
        % if they exist
        iatgeneral.ToolboxPreferencesManager.getOrResetInstance(true);
    catch err %#ok<NASGU>
        % ignore and do nothing
    end
    if ~isdeployed() && usejava('jvm')
        iatbrowser.refreshHardwareList;
    end
catch exception
    throw(exception);     
end
