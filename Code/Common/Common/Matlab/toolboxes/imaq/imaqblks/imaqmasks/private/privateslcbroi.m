function privateslcbroi(dialog, value)
%PRIVATESLCBROI Validates the ROI entry in the IAT SL block.
%
%    PRIVATESLCBROI(DIALOG, VALUE) validates the region of
%    interest (ROI) entered in the dialog mask. 
%

%    SS 09-19-06
%    Copyright 2006-2007 The MathWorks, Inc.

% Get the dialog source object. 
obj = dialog.getDialogSource;

% Convert the string to double vector
% str2double works on scalars. 
roiVector = str2num(value); %#ok<ST2NM>

% Get the error strings.
errorStrings = privateimaqslstring('errorstrings');

%G465436: Situation where model explorer and block mask from Simulink are
%used simultaneously and block mask is closed. At this point, the object
%created underneath is deleted. If ROI is changed at this point in the
%model explorer, it actually errors out mentioning no object is present.
%Performing a dialog refresh creates the object if required. 
if isempty(obj.IMAQObject) || ~isvalid(obj.IMAQObject)
    dialog.refresh();
end

errMsg = localValidateROI(obj, roiVector, errorStrings);

% Display error.
if ~isempty(errMsg)
    % Call T&M function to display error dialog.
    tamslgate('privatesldialogbox', dialog, ...
                                errMsg, ...
                                errorStrings.ErrorDialogTitle);    
    % Restore the previous value on the dialog. 
    obj.Block.ROIPosition = obj.ROIPosition;
    return;
end

% No errors, set the value to the device.
set(obj.IMAQObject,'ROIPosition',roiVector([2 1 4 3]) );

% ROI value set on device may be slightly different. 
actualROIVector = get(obj.IMAQObject, 'ROIPosition');

if any(actualROIVector~=roiVector([2 1 4 3]))
    roiString = sprintf('[%d %d %d %d]', actualROIVector([2 1 4 3]) );
    obj.Block.ROIPosition = roiString;
end

% Assign the ROI position from the block to the source.                                     
obj.Block.ROIPosition = value;
obj.ROIPosition = value;
obj.ROIColumn = num2str(actualROIVector(1));
obj.ROIRow = num2str(actualROIVector(2));
obj.ROIWidth = num2str(actualROIVector(3));
obj.ROIHeight = num2str(actualROIVector(4));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function errMsg = localValidateROI(obj, roiVector, errorStrings)

% Initialize errMsg.
errMsg = [];

% Check for empty.
if isempty(roiVector) || any(~isnumeric(roiVector) | isnan(roiVector) ...     % Check for non-numeric and negative values.
                | isinf(roiVector) | roiVector<0) 
    errMsg = sprintf(errorStrings.InvalidROI);
elseif (length(roiVector)~=4)     % Check for ROI Vector size. 
    errMsg = sprintf(errorStrings.ROIVectorMismatch);
elseif ~(roiVector(3) && roiVector(4)) % Height and width cannot be zero.
    errMsg = errorStrings.ZeroROI;
else
    % NOTE: The convention followed by VIP and IAT is different. The block mask
    % for the From Video Device block follows the VIP standards. 
    % VIP: [row column height width]
    % IAT: [Xoffset Yoffset width height] <--> [column row width height]
    maxVideoResolution = obj.IMAQObject.VideoResolution;
    if (roiVector(1)+ roiVector(3) > maxVideoResolution(2))    
        errMsg = sprintf(errorStrings.MaxHtROI, maxVideoResolution(2));
    elseif (roiVector(2)+ roiVector(4) > maxVideoResolution(1))
        errMsg = sprintf(errorStrings.MaxWidthROI, maxVideoResolution(1));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
