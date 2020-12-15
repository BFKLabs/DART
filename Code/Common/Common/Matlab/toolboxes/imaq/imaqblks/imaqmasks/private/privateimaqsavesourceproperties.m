function privateimaqsavesourceproperties(ddgObj)
%PRIVATEIMAQSAVESOURCEPROPERTIES Stores the source properties permanently.
%
%    PRIVATEIMAQSAVESOURCEPROPERTIES(DDGOBJ) saves the source specific
%    properties for the device when the From Video Device block mask is
%    closed with OK button. DDGOBJ is the dialog source object. 
%

%    SS 09-19-06
%    Copyright 2006 The MathWorks, Inc.

% Get the IMAQ Object.
imaqObj = ddgObj.IMAQObject;

% If no IMAQ Object
if isempty(imaqObj) || ~isvalid(imaqObj)
    return;
end

% Get the selected video source. 
imaqSource = getselectedsource(imaqObj);

blkh = get_param(ddgObj, 'Handle');

% Get all the settable fields. 
allFields = fieldnames(set(imaqSource));

% Loop through all the fields. 
for curField = 1:length(allFields)
    if isnumeric(imaqSource.(allFields{curField}))
        userDataStruct.(allFields{curField}) = double(imaqSource.(allFields{curField}));
    else
        userDataStruct.(allFields{curField}) = imaqSource.(allFields{curField});
    end
end

% Set the user data.
set_param(blkh, 'UserData', userDataStruct);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%