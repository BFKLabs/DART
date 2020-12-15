function out = issending(obj)
%ISSENDING Determine if object is sending.
%
%   OUT = ISSENDING(OBJ) returns a logical array, OUT, that contains a 1
%   where the elements of OBJ are analog output objects whose Sending
%   property is set to 'On' and a 0 where the elements of OBJ are analog
%   output objects whose Sending property is set to 'Off'. 
%
%   See also DAQDEVICE/START, DAQDEVICE/STOP, DAQDEVICE/TRIGGER, DAQHELP.

%   Copyright 2004-2008 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2008/06/16 16:34:48 $

% Determine if an invalid handle was passed.
if ~all(isvalid(obj))
   error('daq:issending:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Get sending state.
% UDD method is named islogging for both AI and AO objects.
out = islogging( daqgetfield(obj,'uddobject') );
