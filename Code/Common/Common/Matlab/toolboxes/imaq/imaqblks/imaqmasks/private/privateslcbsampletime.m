function privateslcbsampletime(dialog, value)
%PRIVATESLCBSAMPLETIME Validates the sample time entry in the IAT SL block.
%
%    PRIVATESLCBSAMPLETIME(DIALOG, VALUE) validates the sample time entry
%    for the from video device block.
%

%    SS 09-19-06
%    Copyright 2006-2007 The MathWorks, Inc.

% Get the dialog source object. 
obj = dialog.getDialogSource;

% Convert sample time to number. 
sampleTime = str2num(value); %#ok<ST2NM>

% Get the error strings. 
errorStrings = privateimaqslstring('errorstrings');

% Check for non-numeric and negative values.
if isempty(sampleTime) || ~isnumeric(sampleTime) || ...
        isnan(sampleTime) || isinf(sampleTime) || sampleTime<=0
    % Call T&M function to display error dialog.
    tamslgate('privatesldialogbox', dialog, ...
                                errorStrings.InvalidSampleTime, ...
                                errorStrings.ErrorDialogTitle);    
    % Restore the previous value on the dialog.                                
    obj.Block.SampleTime = obj.SampleTime;
    return;
end

% Assign the sample time from the block to the source. 
obj.Block.SampleTime = value;
obj.SampleTime = value;