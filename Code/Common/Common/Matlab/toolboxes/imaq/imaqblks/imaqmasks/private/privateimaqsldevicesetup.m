function privateimaqsldevicesetup(obj, allDevices, objConstructors, formats, defaults)
%PRIVATEIMAQSLDEVICESETUP Validates the current device selection.
%
%    PRIVATEIMAQSLDEVICESETUP(OBJ, ALLDEVICES, OBJCONSTRUCTORS, FORMATS, DEFAULTS)
%    validates the device selection value contained in OBJ, a DDG object,
%    using ALLDEVICES, a list of available devices, and OBJCONSTRUCTORS, a list of
%    object constructors. 

%    FORMATS consists of list of all formats supported by the device and
%    DEFAULTS consist of the default format selection for each device. 
%    An associated image acquisition object is also used to update 
%    information for the mask parameters.

%    SS 09-19-06
%    Copyright 2006-2013 The MathWorks, Inc.

localValidateDeviceSelection(obj, allDevices, objConstructors);
localValidateFormatSelection(obj, allDevices, formats, defaults);
localUpdateDeviceSelection(obj);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localValidateDeviceSelection(obj, allDevices, objConstructors)

% If the current device selected is valid, update the device menu and
% return. 
if ismember(obj.Device, allDevices),
    selectedIndex = find( strcmp(allDevices, obj.Device)==true );
    obj.DeviceMenu = obj.Device;
    obj.ObjConstructor = objConstructors{selectedIndex}; %#ok<FNDSB>
    return;
end

errorStrings = privateimaqslstring('errorstrings');

% If the device is invalid and something other than 'none'.
if ~strcmpi(obj.Device,'(none)')
    % Selected device is invalid. 
    if ~strcmpi(allDevices{1},'(none)'),
        msg = sprintf(errorStrings.DifferentDevice, obj.Device, allDevices{1});
    else
        msg = errorStrings.NoDevice;
    end
    
    % Create a modal error dialog. 
    uiwait( errordlg(msg, errorStrings.DeviceErrorTitle, 'modal') );
end

% If the current selection was '(none)' we silently select the first
% available device.
obj.IsDifferentDevice = true;
obj.IsUserDataInvalid = true;
obj.Device = allDevices{1};
obj.DeviceMenu = allDevices{1};
obj.ObjConstructor = objConstructors{1};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localValidateFormatSelection(obj, devices, formats, defaults)

% Determine the selected device index. 
selectedIndex = find( strcmp(devices, obj.Device));
videoFormats = unique( formats{selectedIndex} );

if ~ismember(obj.VideoFormat, videoFormats),
    % Current selection is invalid because:
    %   - the device is same, but does not support this format. 
    %   - the device changed, and so did the format. 
    obj.IsDifferentFormat = true;
    obj.VideoFormat = defaults{selectedIndex};
    obj.VideoFormatMenu = defaults{selectedIndex};
else
    obj.VideoFormatMenu = obj.VideoFormat;
end

% If its a different device, default the value for camera file field.
if obj.IsDifferentDevice
    obj.CameraFile = '';
    obj.Block.CameraFile = '';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localUpdateDeviceSelection(obj)

if strcmpi(obj.Device, '(none)')
    return;
elseif ~(obj.IsDifferentDevice || obj.IsDifferentFormat) && ...
        (~isempty(obj.IMAQObject) && isvalid(obj.IMAQObject))
    return;
elseif obj.IsDifferentDevice || obj.IsDifferentFormat
    if obj.IsDifferentDevice
        obj.SelectedMetadata = '';
    end
    if ~isempty(obj.IMAQObject) && isvalid(obj.IMAQObject)
        % Store if previewing were on. 
        obj.IsPreviewing = strcmpi(obj.IMAQObject.Previewing,'on');
        % Call closepreview. 
        closepreview;
        
        % Close the property inspector.
        src = getselectedsource(obj.IMAQObject);
        if ~isempty(src.InspectorHandle)
            src.InspectorHandle.dispose();
        end
      
        % Delete the listeners.
        delete(obj.ObjectBeingDestroyedListener);
        delete(obj.PropertyChangedListener);        
        
        % Clean up our previous IMAQ object. 
        delete(obj.IMAQObject);
    end
end

% Create the video input object for the device and format selected. 
% Update the object constructor to include the format to be set. 
if ~strcmpi(obj.VideoFormatMenu,'From camera file') % Video Format is selected.
    objectConstructor = strrep(obj.ObjConstructor,')',[',''' obj.VideoFormatMenu ''')']);
    try
        obj.IMAQObject = eval(objectConstructor);
    catch
        % G350453: Mask cannot be opened by dcam FVD is running the
        % simulation. getDialogSchema (and hence
        % privateimaqsldevicesetup.m is called due to triggers during the
        % simulation as well. Due to this, the error message pops up twice
        % while opening the model. It also appears even if you hit cancel
        % button. This field ShowErrorPopUp will avoid the errors appearing
        % at unnecessary times. 
        if obj.ShowErrorPopUp % If true, show the error. 
            if (~any(strcmp(obj.Root.SimulationStatus,{'running','paused', 'terminating'})))
                errorStrings = privateimaqslstring('errorstrings');
                msg = sprintf(errorStrings.ObjectCreationFailed, obj.Device);
                uiwait(errordlg(msg, errorStrings.ErrorDialogTitle, 'modal'));    
            end
            % Set it to false again. 
            obj.ShowErrorPopUp = false; 
        end
        obj.ObjectCreationFailed = true;
        return;
    end
else % Camera file is used as format.
    objectConstructor = strrep(obj.ObjConstructor,')',[',''' obj.CameraFile ''')']);
    try
        obj.IMAQObject = eval(objectConstructor);
    catch %#ok<*CTCH>
        if ~strcmp(obj.CameraFile, '') 
            % Error only if 
            % Camera file field is not empty.
            errorStrings = privateimaqslstring('errorstrings');
            msg = sprintf(errorStrings.WrongCameraFile, obj.CameraFile);
            uiwait(errordlg(msg, errorStrings.ErrorDialogTitle, 'modal'));    
        end
        return;
    end
end

% Object creation passed. 
obj.ObjectCreationFailed = false;

% Set the frames per trigger. 
set(obj.IMAQObject,'FramesPerTrigger',1);

% Get the returned color space.
obj.ReturnedColorSpace = obj.IMAQObject.ReturnedColorSpace;    


% Add listener to user destroying the underlying object from command line.
uddObj = imaqgate('privateGetField', obj.IMAQObject, 'uddobject');
obj.ObjectBeingDestroyedListener = handle.listener(uddObj, ...
    'ObjectBeingDestroyed', {@imaqslcblistener, obj});

% Add listener PropertyPostSet to track ROI changes. 
% Get the video source object.
src = getselectedsource(obj.IMAQObject);
% Get the properties 
props = properties(src);
% Added source object PropertyPostSet listeners.
for i = 1:numel(props)
     obj.PropertyChangedListener = addlistener(src, props{i}, 'PostSet', @(src,evnt)imaqslcblistener(src,evnt,obj));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%