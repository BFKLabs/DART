function [allDevicesForSL, objConstructors, allFormats, defaultFormat, ...
            allDevicesForML, allAdaptors, adaptorsWithDevices, numDevicesForAdaptor] = privateimaqslparsehwinfo(varargin)
%PRIVATEIMAQSLPARSEHWINFO Parse the Image Acquisition Toolbox hardware information.
%
%    [ALLDEVICESFORSL, OBJCONSTRUCTORS, ALLFORMATS, DEFAULTFORMAT, ...
%       ALLDEVICESFORML, ADAPTORS, ADAPTORSWITHDEVICES, ...
%       NUMDEVICESFORADAPTOR] = PRIVATEIMAQSLPARSEHWINFO 
%    parses the Image Acquisition Toolbox hardware information into cell 
%    arrays ALLDEVICESFORSL, and OBJCONSTRUCTORS for all available image
%    acquisition hardware.
%
%    Format for ALLDEVICESFORSL: Color Device(demo-1)
%    Format for ALLDEVICESFORML: demo 1 (Color Device)
%
%    ALLFORMATS is a cell array consisting of list of supported 
%    formats for the specific device and DEFAULTFORMAT consists the default
%    format of the device.

%    SS 09-19-06
%    Copyright 2006-2011 The MathWorks, Inc.

narginchk(0, 1);

% Initialize.
allDevicesForSL = cell(0,1);
objConstructors = cell(0,1);
allFormats = cell(0,1);
defaultFormat = cell(0,1);
allDevicesForML = cell(0,1);
adaptorsWithDevices = cell(0,1);
numDevicesForAdaptor = cell(0,1);

imaqInfo = imaqhwinfo;
allAdaptors = imaqInfo.InstalledAdaptors;
% Return if no adaptors found.
if isempty(allAdaptors)
    allDevicesForSL = {'(none)'};
    allDevicesForML = {'(none)'};    
    objConstructors = {'(none)'};
    allFormats = { {'(none)'} };
    defaultFormat = {'(none)'};
    allAdaptors = {'(none)'};
    adaptorsWithDevices = {'(none)'};
    numDevicesForAdaptor = {0};
    return;
end

% Simulink and System Object have different string representation for
% device file. Simulink calls it 'From camera file' and System Object uses
% 'From device file'. System Object calls this function with
% useDeviceInString set to TRUE.
useDeviceInString = false;
if nargin==1
    useDeviceInString = varargin{1};
end
if useDeviceInString
    str = 'From device file';
else
    str = 'From camera file';
end

nAdaptors = length(allAdaptors);
for iAdaptor = 1:nAdaptors
    % Get the hardware information for a specific adaptor.
    adaptorInfo = imaqhwinfo( allAdaptors{iAdaptor} );

    devInfo = adaptorInfo.DeviceInfo;
    % If there are no devices, continue to next adaptor.
    nDevices = length(devInfo);
    if (nDevices==0)
        continue;
    end

    % Adaptor list with devices.
    adaptorsWithDevices{end+1} = allAdaptors{iAdaptor};
    numDevicesForAdaptor{end+1} = nDevices;
    
    % Determine all the devices, object constructors and video formats.
    for d=1:nDevices
        % Replace invalid chars , and | with white spaces. 
        deviceName = localReplaceInvalidChars(devInfo(d).DeviceName);

        allDevicesForSL{end+1} = sprintf('%s %d (%s)', ... 
            allAdaptors{iAdaptor}, devInfo(d).DeviceID, deviceName); %#ok<*AGROW>
        allDevicesForML{end+1} = sprintf('%s (%s-%d)', ... 
            deviceName, allAdaptors{iAdaptor}, devInfo(d).DeviceID); %#ok<*AGROW>
        
        objConstructors{end+1} = devInfo(d).VideoInputConstructor;
        devFormats = devInfo(d).SupportedFormats;
        
        % Replace invalid chars , and | with white spaces. 
        devFormats = localReplaceInvalidChars(devFormats);

        allFormats{end+1} = devFormats;
        
        % Replace invalid chars , and | with white spaces. 
        formatDefault = localReplaceInvalidChars(devInfo(d).DefaultFormat);
        defaultFormat{end+1} = formatDefault;
        
        if (devInfo(d).DeviceFileSupported) % Check if device file is supported. 
            allFormats{end}{end+1} = str;
            if length(allFormats{end})==1 % If only device file is supported.
                defaultFormat{end} = str;
            end
        end
    end
end

% If there are no devices.
if isempty(allDevicesForSL)
    allDevicesForSL = {'(none)'};
    allDevicesForML = {'(none)'};
    objConstructors = {'(none)'};
    allFormats = { {'(none)'} };
    defaultFormat = {'(none)'};
    adaptorsWithDevices = {'(none)'};
    numDevicesForAdaptor = {0};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output = localReplaceInvalidChars(input)

output = strrep(input, ',', ' ');
output = strrep(output, '|', ' ');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
