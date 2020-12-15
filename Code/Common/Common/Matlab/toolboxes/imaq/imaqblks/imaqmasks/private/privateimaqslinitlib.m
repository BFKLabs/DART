function privateimaqslinitlib
%PRIVATEIMAQINITLIB Initializes the Image Acquisition blockset library.
%
%    PRIVATEIMAQINITLIB populates the from video device block with 
%    information on the available image acquisition hardware.
%
%    SS 09-19-06
%    Copyright 2006-2012 The MathWorks, Inc.

% Set the library block name. 
blockName = 'imaqlib/From Video Device';

styleString = get_param(blockName,'MaskStyleString');
if isempty( findstr(styleString, 'INPUTDEVS') )
    % Block already initialized
    return;
end

% Query the system for the available hardware.
[devices, constructors, formats, defaults] = privateimaqslparsehwinfo;

% Select the default device and constructor.
firstDevice = devices{1};
objConstructor = constructors{1};

% Create popup string for devices.
devices{end+1} = '(none)';
allDevices = localCreatePopUpStrings(devices);

% Create popup string for formats.
formats = unique( [formats{:}] );
formats{end+1} = '(none)';
allFormats = localCreatePopUpStrings(formats);
styleString = strrep(styleString, 'INPUTDEVS', allDevices);
styleString = strrep(styleString, 'INPUTFORMATS', allFormats);

valueString = get_param(blockName, 'MaskValueString');
valueString = strrep(valueString, 'INPUTDEV', firstDevice);
valueString = strrep(valueString, 'CONSTRUCTOR', objConstructor);
valueString = strrep(valueString, 'INPUTFORMAT',defaults{1});

% Find the initial values by creating IMAQ Object.
[sources, ROI, roiHeight, roiWidth, RCS, hwTrigger, triggerConfig] = localFindInitialValues(blockName, objConstructor);

% Select the first source. 
firstSource = sources{1};
blockHandle = get_param(blockName, 'Handle');
blockHandle = num2str(blockHandle);
valueString = strrep(valueString, 'INPUTSRC', firstSource);
valueString = strrep(valueString, 'INPUTROI',ROI);
valueString = strrep(valueString, 'RCS', RCS);
valueString = strrep(valueString, 'CANDOTRIGGER', hwTrigger);
valueString = strrep(valueString, 'CONFIG', triggerConfig);
valueString = strrep(valueString, 'BLOCKHANDLE', blockHandle);
valueString = strrep(valueString, 'ROIHEIGHT', roiHeight);
valueString = strrep(valueString, 'ROIWIDTH', roiWidth);
valueString = strrep(valueString, 'ROIROW', '0');
valueString = strrep(valueString, 'ROICOLUMN', '0');
engXMLPath = fullfile(matlabroot, 'toolbox', 'imaq', 'imaq', 'private');
valueString = strrep(valueString, 'ENGPATH', engXMLPath);
% Update device adaptor location - required if 3p adaptor
adaptorEndIndex = strfind(firstDevice, ' ');
if ~isempty(adaptorEndIndex)
    adaptor = firstDevice(1:adaptorEndIndex(1)-1);
    info = imaqhwinfo(adaptor);
    valueString = strrep(valueString, 'DEVPATH', info.AdaptorDllName);
end
engLibPath = fullfile(matlabroot, 'toolbox', 'imaq', 'imaqblks', 'imaqmex', computer('arch'));
valueString = strrep(valueString, 'ENGLIBPATH', engLibPath);

set_param(blockName, 'MaskStyleString', styleString);
set_param(blockName, 'MaskValueString', valueString);

% Set user data persistent to on. 
set_param(blockName, 'UserDataPersistent', 'on');

% For multi port option, this is required. 
set_param(blockName, 'MaskSelfModifiable','on');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outEntries = localCreatePopUpStrings(entries)

% Create a SL popup string with a list of all devices and all formats. Then remove trailing '|'s.
if isempty(entries)
    outEntries = '';
else
    outEntries = sprintf('%s|', entries{:});
    outEntries = outEntries(1:end-1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [sources, ROI, roiHeight, roiWidth, RCS, hwTrigger, triggerConfig] = localFindInitialValues(blockName, objConstructor)
prevWarningStatus = warning;
warning('off'); %#ok<WNOFF>

try
    % Create the IMAQ Object. 
    imaqobj = eval(objConstructor);
catch %#ok<*CTCH> %If the device supports only camera file, imaq object creation will fail. 
    % Set the initialization to none. 
    sources = {'none'};
    ROI = '(none)';
    roiHeight = '100';
    roiWidth = '100';
    RCS = 'rgb';
    hwTrigger = 'no';
    triggerConfig = 'none/none';
    % Restore the warning settings. 
    warning(prevWarningStatus);
    return;
end
warning(prevWarningStatus);

% Find the video sources.
imaqSource = imaqobj.Source;
sources = {imaqSource(:).SourceName}';

% Region Of Interest. 
roiMax = imaqobj.VideoResolution;
% VIP and IAT follow different conventions in specifying ROI.
ROI = sprintf('[0 0 %s %s]', num2str(roiMax(2)), num2str(roiMax(1)));
roiHeight = num2str(roiMax(2));
roiWidth = num2str(roiMax(1));

% Returned color space: RCS.
RCS = imaqobj.ReturnedColorSpace;

% Can the device do hardware trigger?
triggerInformation = triggerinfo(imaqobj);
if any(ismember({triggerInformation.TriggerType}, 'hardware'))
    hwTrigger = 'yes';
    hwTriggerConfig = triggerinfo(imaqobj,'hardware');
    triggerConfig = cellfun(@strcat,...
        {hwTriggerConfig.TriggerSource}, ...
        strcat('/',{hwTriggerConfig.TriggerCondition}),'UniformOutput',false);
    triggerConfig = triggerConfig{1};
else
    % Hardware trigger not supported.
    hwTrigger = 'no';
    triggerConfig = 'none/none';
end

% Source Properties. 
curSource = getselectedsource(imaqobj);
allFields = fieldnames(set(curSource));

% Loop through all the fields. 
for curField = 1:length(allFields)
    userDataStruct.(allFields{curField}) = curSource.(allFields{curField});
end

set_param(blockName, 'UserData', userDataStruct);

% Clean up - delete the video input object.
delete(imaqobj);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
