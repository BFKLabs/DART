function out = islogging(objects)
%ISLOGGING Determine if video input object is logging.
%
%   OUT = ISLOGGING(OBJ) returns a logical array, OUT, that contains a 1
%   where the elements of OBJ are video input objects whose Logging
%   property is set to 'on' and a 0 where the elements of OBJ are video
%   input objects whose Logging property is set to 'off'. 
%
%   See also IMAQDEVICE/TRIGGERCONFIG, IMAQDEVICE/TRIGGERINFO, IMAQHELP.

%   Copyright 2003-2010 The MathWorks, Inc.

% Error checking.
% Check if there are any invalid video input objects.
if ~all(isvalid(objects)),
    % Find all invalid indexes 
    inval_OBJ_indexes = find(isvalid(objects) == false);

    % Generate an error message specifying the index for the first invalid
    % object found.
    error(message('imaq:islogging:invalidOBJ', inval_OBJ_indexes(1)));
end

% Get logging state.
try
    udd = imaqgate('privateGetField', objects, 'uddobject');
    out = islogging(udd);
catch exception
    throw(exception);
end
