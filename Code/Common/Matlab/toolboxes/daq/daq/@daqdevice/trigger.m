function trigger(obj, event)
%TRIGGER Manually initiate logging/sending for running object.
%
%    TRIGGER(OBJ) executes OBJ's TriggerFcn callback, records the absolute
%    time of the trigger event in OBJ's InitialTriggerTime property, then 
%    configures OBJ's Logging or Sending property to 'On'.  OBJ can be either 
%    a single device object or an array of device objects.
%
%    TRIGGER can only be invoked if OBJ is running and its TriggerType
%    property is set to 'Manual'.
%
%    The Trigger event is recorded in OBJ's EventLog property.
%
%    TRIGGER may be called by a data acquisition object's event callback e.g.,
%    obj.StartFcn = @trigger;
%
%    See also DAQHELP, DAQDEVICE/START, STOP, PROPINFO.
%

%    MP 4-10-98   
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.11.2.7 $  $Date: 2008/06/16 16:35:27 $

if nargout>0,
   error('daq:trigger:argcheck', 'Too many output arguments.')
end

% If two inputs are given, verify that the second input is the event
% structure otherwise error.
if nargin == 2
   if ~(isfield(event, 'Type') && isfield(event, 'Data'))
      error('daq:trigger:argcheck', 'Too many input arguments.');
   end
end

% Error if a digitalio object is passed.
if isa(obj, 'digitalio')
   error('daq:trigger:invalidobject', 'OBJ must be an analog input or analog output object.');
end

% Determine if an invalid handle was passed.
if ~all(isvalid(obj))
   error('daq:trigger:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

uddobjs = daqgetfield(obj,'uddobject');
if ( strcmpi(class(uddobjs),'daq.device' ) )
   % Must loop through each object is they are a mixture since UDD
   % doesn't handle this when daq.device doesn't implement trigger.
   for i = 1:length(uddobjs)
       trigger( uddobjs(i) );
   end
else
   trigger( uddobjs );
end
