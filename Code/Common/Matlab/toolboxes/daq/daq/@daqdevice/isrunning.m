function out = isrunning(obj)
%ISRUNNING Determine if object is running.
%
%   OUT = ISRUNNING(OBJ) returns a logical array, OUT, that contains a 1
%   where the elements of OBJ are device objects whose Running
%   property is set to 'On' and a 0 where the elements of OBJ are device
%   objects whose Running property is set to 'Off'. 
%
%   See also DAQDEVICE/START, DAQDEVICE/STOP, DAQHELP.

%   Copyright 2004-2008 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2008/06/16 16:35:14 $

% Determine if an invalid handle was passed.
if ~all(isvalid(obj))
   error('daq:isrunning:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Get running state.
out = isrunning( daqgetfield(obj,'uddobject') );
