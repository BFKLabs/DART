function wait(obj, waittime)
%WAIT Wait for the data acquisition object to stop running.
%
%    WAIT(OBJ,WAITTIME) waits for the OBJ's Running property to go
%    to 'Off'. The WAITTIME specifies the maximum time in seconds to
%    wait before causing a time out error.  It is not guaranteed that the 
%    OBJ's StopFcn will be called before this function returns.
%    OBJ can be either a single device object or an array of device objects.
%    When OBJ is an array of objects then this function will wait on each 
%    object separately and therefore could wait for up to N times the WAITTIME
%    where N is the number of objects passed in.
%    If the object is not running or has an error this function will return
%    immediately.
%
%    OBJ can stop running under one of the following conditions:
%       1. When the requested samples are acquired (analog input) or sent 
%          out (analog output).  For analog input, this occurs when OBJ's
%          SamplesAcquired equals the product of OBJ's SamplesPerTrigger 
%          and TriggerRepeat properties.
%       2. A runtime error occurs.
%       3. OBJ's Timeout value is reached.
%
%    The Stop event is recorded in OBJ's EventLog property.
%
% 
%    See also DAQHELP, DAQDEVICE/START, DAQDEVICE/STOP, TRIGGER, PROPINFO.
%

%    PB 9-1-99
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.1.6.3 $  $Date: 2008/06/16 16:35:28 $

% Check to see if waittime is specified.
if (nargin == 1)
	error('daq:wait:timenotspecified', 'WAITTIME must be specified.');
end

% Determine if an invalid handle was passed.
if ~all(isvalid(obj))
   error('daq:start:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

uddobjs = daqgetfield(obj,'uddobject');
if ( strcmpi(class(uddobjs),'daq.device' ) )
    % Must loop through each object if they are a mixture since UDD
    % doesn't handle this when daq.device doesn't implement wait.
    for i = 1:length(uddobjs)
        wait( uddobjs(i), waittime );
    end
else
    wait( uddobjs, waittime );
end

