function privatesetvideosourceprops(imaqObj, sourceProps)
%PRIVATESETVIDEOSOURCEPROPS Sets the video source properties on the device.
%
%    PRIVATESETVIDEOSOURCEPROPS(IMAQOBJ, SOURCEPROPS) sets the video
%    source properties, specified by SOURCEPROPS, on device, IMAQOBJ. 

%    SS 09-19-06
%    Copyright 2006-2011 The MathWorks, Inc.

% Just incase user modified it. 
if isempty(sourceProps) || ~isstruct(sourceProps)
    return;
end

% Get all the fields.
userDataFields = fieldnames(sourceProps);

% Get the selected video source.
imaqSource = getselectedsource(imaqObj);
% Get all the settable fields.
propFields = fieldnames(set(imaqSource));

% Loop through all the fields. 
for curField = 1:length(userDataFields)
    % Check if the field in sourceProps structure exists in the video source
    % object.
    % Purpose: 
    % a. Trying to catch a case if the device property were to be removed or
    % b. If new fields are added between versions, we want to load all the 
    % saved fields correctly.
    try 
        if ismember(userDataFields{curField}, propFields)
            imaqSource.(userDataFields{curField}) = ...
                sourceProps.(userDataFields{curField});
        end
    catch %#ok<CTCH>
        warning(message('imaq:imaqblks:sourcePropsSetting', userDataFields{curField}));
    end
end