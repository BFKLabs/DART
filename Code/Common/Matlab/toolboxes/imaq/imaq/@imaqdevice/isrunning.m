function out = isrunning(objects)
%ISRUNNING Determine if video input object is running.
%
%   OUT = ISRUNNING(OBJ) returns a logical array, OUT, that contains a 1
%   where the elements of OBJ are video input objects whose Running
%   property is set to 'on' and a 0 where the elements of OBJ are video
%   input objects whose Running property is set to 'off'. 
%
%   See also IMAQDEVICE/START, IMAQDEVICE/STOP, IMAQHELP.

%   Copyright 2003-2010 The MathWorks, Inc.

% Error checking.
% Check if there are any invalid video input objects.
if ~all(isvalid(objects)),
    % Find all invalid indexes 
    inval_OBJ_indexes = find(isvalid(objects) == false);

    % Generate an error message specifying the index for the first invalid
    % object found.
    error(message('imaq:isrunning:invalidOBJ', inval_OBJ_indexes(1)));
end

% Get running state.
try
    udd = imaqgate('privateGetField', objects, 'uddobject');
    out = isrunning(udd);
catch exception
    throw(exception);
end
