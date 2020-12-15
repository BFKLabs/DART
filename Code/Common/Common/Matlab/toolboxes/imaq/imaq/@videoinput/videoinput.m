function obj = videoinput(varargin)
%VIDEOINPUT Create video input object.
% 
%    OBJ = VIDEOINPUT(ADAPTORNAME)
%    OBJ = VIDEOINPUT(ADAPTORNAME,DEVICEID)
%    OBJ = VIDEOINPUT(ADAPTORNAME,DEVICEID,FORMAT)
%    OBJ = VIDEOINPUT(ADAPTORNAME,DEVICEID,FORMAT,P1,V1,...)
%
%    OBJ = VIDEOINPUT(ADAPTORNAME) constructs the video input object, OBJ. 
%    A video input object represents the connection between MATLAB and a
%    particular image acquisition device. ADAPTORNAME is a text string that
%    specifies the name of the adaptor used to communicate with the device.
%    Use the IMAQHWINFO function to determine the adaptors available on
%    your system.
%
%    OBJ = VIDEOINPUT(ADAPTORNAME,DEVICEID) constructs a video input
%    object OBJ, where DEVICEID is a numeric scalar value that identifies a
%    particular device available through the specified adaptor, ADAPTORNAME.
%    Use the IMAQHWINFO(ADAPTORNAME) syntax to determine the devices
%    available through the specified adaptor. If DEVICEID is not specified,
%    the first available device ID is used. As a convenience, a device's name
%    can be used in place of the DEVICEID. If multiple devices have the same
%    name, the first available device is used.
%
%    OBJ = VIDEOINPUT(ADAPTORNAME,DEVICEID,FORMAT) constructs a video input
%    object, where FORMAT is a text string that specifies a particular
%    video format supported by the device or the full path of a device
%    configuration file (also known as a camera file). 
%
%    To get a list of the formats supported by a particular device, view the
%    DEVICEINFO structure for the device that is returned by the IMAQHWINFO
%    function. Each DEVICEINFO structure contains a SUPPORTEDFORMATS field.
%    If FORMAT is not specified, the device's default format is used.
%
%    When the video input object is created, its VIDEOFORMAT field contains
%    the format name or device configuration file that you specify.
%
%    OBJ = VIDEOINPUT(ADAPTORNAME,DEVICEID,FORMAT,P1,V1,...) creates a video 
%    input object OBJ with the specified property values. If an invalid 
%    property name or property value is specified, the object is not created.
%
%    The property name and property value pairs can be in any format supported
%    by the SET function, i.e., parameter/value string pairs, structures, or 
%    parameter/value cell array pairs.  
%  
%    To view a complete listing of video input functions and properties, use 
%    the IMAQHELP function:
%
%       imaqhelp videoinput
%
%    The toolbox chooses the first available video source object as the 
%    selected source and specifies this video source object's name in the
%    object's SELECTEDSOURCENAME property. Use GETSELECTEDSOURCE(OBJ) to
%    access the video source object that is used for acquisition. 
% 
%    Example:
%       % Construct a video input object associated 
%       % with a Matrox device at ID 1.
%       obj = videoinput('matrox', 1);
%
%       % Select the source to use for acquisition. 
%       set(obj, 'SelectedSourceName', 'input1')
%
%       % View the properties for the selected video source object.
%       src_obj = getselectedsource(obj);
%       get(src_obj)
%
%       % Preview a stream of image frames.
%       preview(obj);
%
%       % Acquire and display a single image frame.
%       frame = getsnapshot(obj);
%       image(frame);
%
%       % Remove video input object from memory.
%       delete(obj);
% 
%    See also DELETE, IMAQHWINFO, IMAQFIND, IMAQDEVICE/ISVALID, IMAQDEVICE/PREVIEW

%    CP 9-01-01
%    Copyright 2001-2013 The MathWorks, Inc.

% Initializing fields for MATLAB OOPs object.
className = 'videoinput';
parentClassName = 'imaqdevice';
try
    obj.version = imaqmex;
catch exception
    throw(exception)
end
obj.type = {className};
obj.constructor = className;
obj.data.objtype = 'Video Input';

% Create the parent for the class.
parent = imaqdevice(parentClassName);

%%%%%%%%%%%%%%%%%%%%%%%%
% Parse Input Arguments.
%
% Syntax checking is performed later. For now, just extract
% the inputs into our own variables.
PVpairs = {};
switch(nargin),
case 0,
    % Default constructor.
    error(message('imaq:videoinput:adaptorID'));
case 1,
    if strcmp(class(varargin{1}), className)
        % Return the object as is.
        obj = varargin{1};
        return;
    elseif ~isempty(strfind( class(varargin{1}), 'imaq.') ) || ...
            strcmp(class(varargin{1}), 'handle'),
        % Note: Can't just use ISHANDLE here. Need to check the class since 
        %       we could encounter videoinput(audiorecorder).
        %
        % Also, we need to allow inputs of class handle in order to load
        % invalid objects via LOADOBJ.
        %
        % This is used by SUBSREF/SUBSASGN/IMAQFIND to convert a UDD object
        % to the proper MATLAB OOPS class.
        %
        % Store UDD object and create new MATLAB object.
        obj.uddobject = varargin{1};
        obj = class(obj, className, parent);
        return;
    elseif isstruct(varargin{1}) && isfield(varargin{1}, parentClassName) && ...
            isa(varargin{1}.imaqdevice, parentClassName),
        % We were provided a previously constructed videoinput structure.
        %
        % Note: Since MATLAB adds a field for the parent when
        %       creating a new object with CLASS, we first need 
        %       to remove the existing dummy parent object.
        objStruct = rmfield(varargin{1}, parentClassName);
        obj = class(objStruct, className, parent);
        return;
    else
        % obj = videoinput('matrox');
        % Leave format and device ID option empty for now. We'll use defaults later.
        adaptorName = varargin{1};
        deviceID = [];
        formatType = '';
    end
case 2,
    % obj = videoinput('matrox', 1);
    % Leave format option empty for now. We'll use default FORMAT later.
    adaptorName = varargin{1};
    deviceID = varargin{2};        
    formatType = '';
otherwise,
    % Check the syntax case used later on. For now, assume 3rd input is 
    % the format option as long as it is not empty.
    adaptorName = varargin{1};
    deviceID = varargin{2};
    formatType = varargin{3};
    
    % Make sure that a non-empty format was specified.
    if isempty(formatType)
        error(message('imaq:videoinput:noFormat'));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%
% Input Error Checking
%
% Convert string ID's to a double. Provided as a convenience.
if ischar(deviceID),    
    % If the device ID is a non-numeric string (like 'Intel Camera'), 
    % NaN is returned. Since device names are also accepted, keep the 
    % old device ID if this turns out to be the case.
    tempDeviceID = str2double(deviceID);
    if ~isnan(tempDeviceID),
        deviceID = tempDeviceID;
    end
end

% Device ID error checking.
if nargin>1,
    % Allow non-double numerics to come through.
    if isnumeric(deviceID) && ~isa(deviceID, 'double'),
        deviceID = double(deviceID);
    end
    
    if isempty(deviceID)
        error(message('imaq:videoinput:emptyID'));
    elseif ~isa(deviceID, 'double') && ~ischar(deviceID),
        error(message('imaq:videoinput:notAnID'));
    elseif deviceID < 0
        error(message('imaq:videoinput:negativeID'));
    end
end

% Source format error checking.
if ~ischar(formatType)
    error(message('imaq:videoinput:strFormat'));
end

% Adaptor name error checking.
if ~ischar(adaptorName)
    error(message('imaq:videoinput:strAdaptor'));
end

if isempty(adaptorName)
    error(message('imaq:videoinput:emptyAdaptor'));
end

adaptorName = imaqgate('privateTranslateAdaptor', adaptorName);


% Disable support package warning as this is a separate API.
prevWarn = warning('off', 'imaq:imaqhwinfo:additionalVendors');
% Make sure that the user specified a valid adaptor name.
hwinfo = imaqhwinfo;
if ~any(ismember(lower(hwinfo.InstalledAdaptors), lower(adaptorName)))
    warning(prevWarn);
    error(message('imaq:videoinput:invalidAdaptorName'));
end

% Restore warning.
warning(prevWarn);

% Locate the adaptor files. 
adaptorName = lower(adaptorName);
try
    hwInfo = imaqhwinfo(adaptorName);
catch exception
    throw(exception);
end

% Check that device are actually available.
if isempty(hwInfo.DeviceIDs),
    error(message('imaq:videoinput:noDevices'));
end

% DLLs are PC specific.
if ispc,
    adaptorExtension = '.dll';
elseif strfind(lower(computer), 'glnx')
    adaptorExtension = '.so';
else
    adaptorExtension = '.dylib';
end

xmlPath = strrep(hwInfo.AdaptorDllName, adaptorExtension, '.imdf');
% Make sure the file exists.
if exist(xmlPath, 'file')~=2,
    xmlPath = '';
end

% If no device ID was specified, use the first one.
if isempty(deviceID),
    deviceID = hwInfo.DeviceIDs{1};
end

% Locate the numerical device ID if we are dealing with numerical IDs.
infoIndex = [];
if ~ischar(deviceID),
    infoIndex = find(deviceID == [hwInfo.DeviceIDs{:}]);
end

% Verify that IMAQHWINFO is available for this adaptor.
if isempty(infoIndex),
    % We may be dealing with device names. Check if there's 
    % a match for the device name provided.
    deviceNameMatch = strcmpi(deviceID, {hwInfo.DeviceInfo.DeviceName});
    nameMatchIndices = find(deviceNameMatch==true);
    if ~isempty(nameMatchIndices)
        % A device name was provided. Use the ID for the first match.
        infoIndex = nameMatchIndices(1);
        deviceID = hwInfo.DeviceIDs{infoIndex};
    else
        error(message('imaq:videoinput:invalidID'));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Syntax Checking
%
% Determine the board name, supported formats, and the 
% format to use.
requestedDevice = hwInfo.DeviceInfo(infoIndex);
deviceFileOK = requestedDevice.DeviceFileSupported;
defaultFormat = requestedDevice.DefaultFormat;
supportedFormats = requestedDevice.SupportedFormats;
checkSupported = strcmpi(formatType, supportedFormats);

% Error gracefully if device files are supported, and there is no default
% format and the user does not supply a camera file.
if deviceFileOK && isempty(defaultFormat) && isempty(formatType)
    error(message('imaq:videoinput:cameraFileRequiredNoneSupplied'));
end

% Based on the syntax called, determine the format option and
% extract any PV pairs present.
if isempty(formatType),
    % Checking:
    %   obj = videoinput('matrox', 1);
    %
    % We need to assign the default format from IMAQHWINFO.
    formatType = defaultFormat;
elseif nargin>=3,
    if any(checkSupported),
        % Checking:
        %   obj = videoinput('matrox', 1, 'rs170', ...);
        %
        % No PV pairs to extract, so keep it empty.
        % Use the format name from IMAQHWINFO to preserve case.
        supportedIndex = find(checkSupported==true);
        formatType = supportedFormats{supportedIndex(1)};
    else
        % Checking:
        %   obj = videoinput('matrox', 1, 'D:\MyCameraFile.dcf', ...);
        %
        % The format is already set to the camera file. Make sure the
        % file includes a path.
        [formatType, fileFlag] = localAddPathToFile(formatType);
        if ~deviceFileOK && fileFlag,
            % User input looked like DEVICEFILE, but device 
            % doesn't support them.
            error(message('imaq:videoinput:noFile'));
        elseif ~fileFlag && ~deviceFileOK
            % User input looked like FORMAT.
            error(message('imaq:videoinput:noFormat'));
        end
    end
    
    % Checking:
    %   obj = videoinput('matrox', 1, 'rs170', P1, V1, ...);
    %   obj = videoinput('matrox', 1, 'D:\MyCameraFile.dcf', P1, V1, ...);
    if nargin>3,
        PVpairs = varargin(4:end); 
    end
end

% Create the new UDD and MATLAB OOPs object.
try
    % Find the engine XML file.
    engXML = which('imaqmex.imdf', '-all');

    % Register the schema definitions, schemaName will be something like demo1_1
    % registerSchemas calls imaq::schemafcns::defineObjectSchemas
    % imaq::schemafcns::defineObjectSchemas calls imaq::schemafcns::addAdaptorSpecifics
    % addAdaptorSpecifics creates the AdaptorPropFactory
    %     the  childPropFact is the AdaptorPropFactory's internal factory
    %                         and the VideoSourceInfoContainer
    %                         and then calls initDynamicAdaptorInfo and passes it the AdaptorPropertyFactory
    % initDynamicAdaptorInfo calls getDeviceAttributes passing it the AdaptorPropertyFactory
    schemaName = imaqmex('registerSchemas', adaptorName, ...
        deviceID, formatType, xmlPath, engXML{1});

    % Construct the parent UDD object.
    pack = findpackage('imaq');
    uddParent = eval(['imaq.', schemaName, '(adaptorName, deviceID, formatType);']);
    connect(uddParent, pack.DefaultDatabase, 'up');
    
    nSrcs =  uddParent.getnumberofdevicesources();
    srcNames = uddParent.getnamesofdevicesources();
    propContainer = imaqmex('getPropertyContainer', schemaName, nSrcs, srcNames);

    % Finish building the parent OOPs.
    obj.uddobject = uddParent;
    obj = class(obj, className, parent);
    
    % Construct a MCOS object for each device source.
    mcosChildren = videosource.empty;
    for s = 1:nSrcs
        mcosChildren = [mcosChildren videosource(srcNames{s}, obj, propContainer)]; %#ok<AGROW>
    end
    
    % Link the parent to its children and adaptor.
    uddParent.addchildren(propContainer, obj, mcosChildren);
    try
        uddParent.linktoadaptor;
    catch exception
        delete(uddParent);
        throw(exception);
    end

    % Store the constructor arguments. These are needed to save and load.
    % TODO: this property should not be accessible via OOPs.
    p = schema.prop(obj.uddobject, 'ObjectConstructorArguments', 'MATLAB array');
    obj.uddobject.ObjectConstructorArguments = {adaptorName, deviceID, formatType};
    p.AccessFlags.PublicSet = 'off';
    p.Visible = 'off';

    p = schema.prop(obj.uddobject, 'ObjectGUID', 'int32');
    obj.uddobject.ObjectGUID = int32(fix(rand * 2^31));
    p.Visible = 'off';
catch exception
    throw(exception);
end
  
% Assign the properties.
if ~isempty(PVpairs)
   try
      set(obj, PVpairs{:});
   catch exception
      delete(obj); 
      throw(exception);
   end
end

% Assign a property post set listener to the uddobject for handling any
% actions we might want to react to.
tokens = regexp(class(obj.uddobject), '(.*)\.(.*)', 'tokens');
packageName = tokens{1}{1};
className = tokens{1}{2};
pk = findpackage(packageName);
cls = pk.findclass(className);
props = get(cls, 'Properties');
p = schema.prop(obj.uddobject, 'PropertyPostSetListener', 'handle');
obj.uddobject.PropertyPostSetListener = ...
    handle.listener(obj.uddobject, props, 'PropertyPostSet', ...
                    {@localHandlePropertyChanged, obj});
p.Visible = 'off';


function localHandlePropertyChanged(property, event, obj)
% If the property being changed is the DiskLogger and it is being set to a
% non-empty value, warn if the native data type is 16 bit as AVI files
% only support 8 bits.
isDiskLogger = strcmp(get(property, 'Name'), 'DiskLogger');
newValue = get(event, 'NewValue');

if isDiskLogger && ...
        ~isempty(newValue) && ...
        strcmp(getfield(imaqhwinfo(obj), 'NativeDataType'), 'uint16') %#ok<GFLD>
    
    S = warning('off', 'backtrace');
    cleaner = onCleanup(@()warning(S));

    if isa(newValue, 'avifile') || ~strcmpi(newValue.FileFormat, 'mj2')
        warning(message('imaq:set:diskLogger:aviOnGT8bitFormat'));
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [newDeviceFile, fileFlag] = localAddPathToFile(deviceFile)
% Adds the path to the device file if none are present.
% Also returns a flag indicating if the format looks 
% like a device file.

% Initialize.
fileFlag = true;
newDeviceFile = deviceFile;

% Check to see if a path was already present, because if 
% it was, there's nothing more for us to do.
[pathStr, fileName, fileExt] = fileparts(deviceFile); %#ok<ASGLU>
if isempty(pathStr),
    % If no file extension was provided either, 
    % must assume it's not a device file.
    if isempty(fileExt)
        fileFlag = false;
    end
    
    % Try to add a path and extension (via WHICH). If file is
    % '-', WHICH errors. If the file is a MATLAB operator, WHICH
    % returns a path, so we need to check for that.
    try
        pathLocation = which(deviceFile);
        if ~isempty(findstr(pathLocation, fullfile('matlab', 'ops'))),
            pathLocation = '';
        end
    catch %#ok<CTCH>
        pathLocation = '';
    end
    
    if ~isempty(pathLocation),
        newDeviceFile = pathLocation;
        fileFlag = true;
    end
end
