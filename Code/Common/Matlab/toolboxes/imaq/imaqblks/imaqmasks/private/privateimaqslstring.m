function outputStringStruct = privateimaqslstring(inputString)
%PRIVATEIMAQSLSTRING Return a string struct used by simulink IAT MATLAB code.
%
%    OUTPUTSTRINGSTRUCT = PRIVATEIMAQSLSTRING(INPUTSTRING) returns a
%    structure, OUTPUTSTRINGSTRUCT that contains message strings specific
%    to the input query passed in INPUTSTRING.
%    Valid values for INPUTSTRING are:
%    1. 'ErrorStrings'
%    2. 'Tags'

%    SS 09-22-06
%    Copyright 2006-2011 The MathWorks, Inc.


% Return the structure requested by the input string.
switch lower(inputString)
    case 'errorstrings' %Error Strings.
        outputStringStruct = localInitErrorStrings([]);
    case 'tags' %Widget tags only.
        outputStringStruct = localInitWidgetTags([]);
    otherwise
        % Assert as wrong input string is provided. 
        assert(false, 'imaq:imaqblks:InvalidString', 'Wrong input string.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function structToReturn = localInitWidgetTags(structToReturn)

% Initializes all widget tags.
structToReturn.ParameterPane = 'ParameterPane';
structToReturn.Description = 'Description';
structToReturn.DescriptionPane = 'DescriptionPane';
structToReturn.DeviceMenu = 'DeviceMenu';
structToReturn.Device = 'Device';
structToReturn.VideoFormatMenu = 'VideoFormatMenu';
structToReturn.VideoFormat = 'VideoFormat';
structToReturn.CameraFile = 'CameraFile';
structToReturn.Browse = 'Browse';
structToReturn.VideoSource = 'Video-Source';
structToReturn.EditProperties = 'EditProperties';
structToReturn.EnableHWTrigger = 'EnableHWTrigger';
structToReturn.TriggerConfiguration = 'TriggerConfiguration';
structToReturn.ROIPosition = 'ROIPosition';
structToReturn.Preview = 'Preview';
structToReturn.SampleTime = 'SampleTime';
structToReturn.OutputPortsMode = 'OutputPortsMode';
structToReturn.DataType = 'DataType';
structToReturn.ColorSpace = 'ColorSpace';
structToReturn.BayerSensorAlignment = 'BayerSensorAlignment';
structToReturn.MetadataPane = 'MetadataPane';
structToReturn.AllMetadata = 'All-Metadata';
structToReturn.SelectedMetadata = 'Selected-Metadata';
structToReturn.AddButton = 'AddButton';
structToReturn.RemoveButton = 'RemoveButton';
structToReturn.MoveDownButton = 'MoveDownButton';
structToReturn.MoveUpButton = 'MoveUpButton';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function structToReturn = localInitErrorStrings(structToReturn)

% Initializes the error strings. 

% No device exists.
structToReturn.NoDevice = sprintf('No video input devices are available.');

% Loading error: Device selected no longer exists. 
structToReturn.DifferentDevice = ['Image acquisition device ''%s'' is ' ...
    'unavailable.\nThe ''%s'' device will be selected.'];

structToReturn.DeviceErrorTitle = sprintf('Device Selection Error');

% Wrong camera file specified. 
structToReturn.WrongCameraFile = ['The camera file ''%s'' is invalid. '...
                                    'Please enter a valid camera file.'];

                                
% ROI consists of invalid entries.
structToReturn.InvalidROI = sprintf(...
                   'The Region of Interest (ROI) vector must consist of positive numeric values.');

structToReturn.ZeroROI = sprintf(...
                   'The height and width of the output frame cannot be zero.');

structToReturn.MaxHtROI = ['The height specified for video ' ...
                           'resolution has been exceeded.\nThe maximum '...
                           'possible frame height is %d.'];

structToReturn.MaxWidthROI = ['The width specified for video ' ...
                           'resolution has been exceeded.\nThe maximum '...
                           'possible frame width is %d.'];
                       
structToReturn.ROIVectorMismatch = ['The region of interest (ROI) must be '...
                                    'specified as a row vector\nin the following format: '...
                                    '[row column height width].'];
                                
structToReturn.InvalidSampleTime = ...
    sprintf('Sample time must be specified as a positive real number.');

structToReturn.ErrorDialogTitle = sprintf('Configuration Error');

structToReturn.ObjectCreationFailed = 'The device ''%s'' has been removed or is already in use.';

structToReturn.ProblemWithPreviewing = 'The device ''%s'' may be already in use.';

% Message displayed when object is destroyed.
structToReturn.ObjectBeingDestroyed = ...
    ['The object created by a Simulink block named ''%s'' was deleted at the command line.', ...
    ' The dialog box corresponding to the ''%s'' block will be closed.', ...
    '\n\nDo you want to save the current settings of this block?'];

% Dialog title for message pop up when object is destroyed.
structToReturn.ObjectBeingDestroyedDlgTitle = sprintf('Object deleted by the user');

% Warning when user opens an old block.
structToReturn.OldBlockWarning = sprintf('Video Input block has been obsoleted. Please update your model with the new From Video Device block.');
structToReturn.WarnID = sprintf('imaq:imaqblks:oldBlockLoading');

structToReturn.ImaqResetWarning = sprintf(['Continuing with Simulink Rapid Accelerator mode will delete all image acquisition objects ' ...
                          'created within MATLAB.\n\nDo you wish to continue?']);
structToReturn.ImaqResetWarningDlg = sprintf('Continue Simulink Rapid Accelerator mode?');

structToReturn.SourcePropsWarningID = sprintf('imaq:imaqblks:sourcePropsSetting');
structToReturn.SourcePropsWarning = 'Unable to set the source property %s on the device.';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%