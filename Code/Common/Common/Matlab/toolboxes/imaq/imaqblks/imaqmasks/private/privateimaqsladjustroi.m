function privateimaqsladjustroi(ddgObj)
%PRIVATEIMAQSLADJUSTROI Adjusts the ROI settings to device supported values. 
%
%    PRIVATEIMAQSLADJUSTROI(DDGOBJ) adjusts the ROIPosition value on the
%    source object, DDGOBJ, to a value supported by the device. 

%    SS 11-13-06
%    Copyright 2006 The MathWorks, Inc.

% Get the IMAQ Object. 
imaqobj = ddgObj.IMAQObject;

% Get the ROI Position from the object. 
roiPosition = get(imaqobj, 'ROIPosition');

% Convert ROI Position to string. 
roiString = sprintf('[%d %d %d %d]', roiPosition([2 1 4 3]) );

% Assign the values to source objects ROI property. 
ddgObj.ROIPosition = roiString;
ddgObj.Block.ROIPosition = roiString;
ddgObj.ROIColumn = num2str(roiPosition(1));
ddgObj.ROIRow = num2str(roiPosition(2));
ddgObj.ROIWidth = num2str(roiPosition(3));
ddgObj.ROIHeight = num2str(roiPosition(4));