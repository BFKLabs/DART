function stop(obj, event)
%STOP Stop data acquisition object running and logging/sending.
%
%    STOP(OBJ) configures OBJ's Running property to 'Off'.  STOP also 
%    configures OBJ's Logging or Sending properties to 'Off' if needed, 
%    then executes OBJ's StopFcn callback.  OBJ can be either 
%    a single device object or an array of device objects.
%
%    OBJ can also stop running under one of the following conditions:
%       1. When the requested samples are acquired (analog input) or sent 
%          out (analog output).  For analog input, this occurs when OBJ's
%          SamplesAcquired = SamplesPerTrigger * (1 + TriggerRepeat)
%       2. A runtime error occurs.
%       3. OBJ's Timeout value is reached.
%
%    The Stop event is recorded in OBJ's EventLog property.
%
%    STOP may be called by a data acquisition object's event callback e.g.,
%    obj.TimerFcn = {'stop'};
% 
%    See also DAQHELP, DAQDEVICE/START, TRIGGER, PROPINFO, DAQDEVICE/WAIT.
%

%    PB 1-1-01
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.12.2.7 $  $Date: 2008/06/16 16:35:24 $

if nargout > 0
   error('daq:stop:argcheck', 'Too many output arguments.')
end

% If two inputs are given, verify that the second input is the event
% structure otherwise error.
if nargin == 2
   if ~(isfield(event, 'Type') && isfield(event, 'Data'))
      error('daq:stop:argcheck', 'Too many input arguments.');
   end
end

% Determine if an invalid handle was passed.
if ~all(isvalid(obj))
   error('daq:stop:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Stop the object.
stop( daqgetfield(obj,'uddobject') );
