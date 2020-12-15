function privateimaqloadsourceproperties(ddgObj)
%PRIVATEIMAQLOADSOURCEPROPERTIES Loads the source properties.
%
%    PRIVATEIMAQLOADSOURCEPROPERTIES(DDGOBJ) loads the source specific
%    properties for the device when the From Video Device block mask is
%    opened. DDGOBJ is the dialog source object. 
%

%    SS 09-19-06
%    Copyright 2006 The MathWorks, Inc.

% Get the IMAQ Object. 
imaqObj = ddgObj.IMAQObject;

% If no IMAQ Object, return. 
% ISCALLBACKCALLED: If mask were already open and this function was
% called by a callback, we do not want to overwrite source properties that
% the user may have changed while the mask were open. ISCALLBACKCALLED is
% true if this call is a result of a mask callback. ISCALLBACKCALLED is
% false if the user is opening the mask to see the properties.
%
% ISDIFFERENTDEVICE, ISDIFFERENTFORMAT, ISDIFFERENTSOURCE - If the device, 
% format or source is changed (either by user, or if the
% device/format/source no longer exist), then we do not want to proceed
% further. 


if ( (isempty(imaqObj)) || (~isvalid(imaqObj)) || (ddgObj.IsCallbackCalled)...
                || ddgObj.IsDifferentDevice || ddgObj.IsDifferentFormat ...
                || ddgObj.IsDifferentSource)
    return;
end

blkh = get_param(ddgObj, 'Handle');
sourceProps = get(blkh, 'UserData');
privatesetvideosourceprops(imaqObj, sourceProps); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%