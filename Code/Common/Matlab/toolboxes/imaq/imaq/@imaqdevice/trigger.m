function trigger(obj, event)
%TRIGGER Manually initiate data logging.
%    
%    TRIGGER(OBJ) initiates data logging for video input object OBJ.
%    OBJ must be started with the START function before it can be 
%    manually triggered. OBJ can be either a single or an array of video 
%    input objects.
%
%    When an acquisition is triggered, OBJ performs the following operations:
%        1. Executes OBJ's TriggerFcn callback
%        2. Records the absolute time of the first trigger event in OBJ's 
%           InitialTriggerTime property
%        3. Configures OBJ's Logging property to 'On'. 
%    
%    TRIGGER can only be invoked if OBJ is running and its TriggerType
%    property is set to 'manual'. Use TRIGGERCONFIG to configure OBJ's
%    TriggerType property.
%    
%    The Trigger event is recorded in OBJ's EventLog property.
%    
%    TRIGGER may be called by a video input object's event callback e.g.,
%    obj.StartFcn = @trigger;
%    
%    See also IMAQHELP, IMAQDEVICE/START, IMAQDEVICE/STOP, IMAQDEVICE/TRIGGERCONFIG, 
%             IMAQDEVICE/PROPINFO.

%    RDD 7-17-02
%    Copyright 2001-2010 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'imaqdevice')
    error(message('imaq:getdata:invalidType'));
elseif ~isvalid(obj)
    error(message('imaq:getdata:invalidOBJ'));
end

% Verify the second input is the event structure.
if nargin == 2
   if ~(isfield(event, 'Type') && isfield(event, 'Data'))
      error(nargchk(1, 1, nargin, 'struct'));
   end
end

% Call trigger to generate a manual trigger.
try
    trigger(imaqgate('privateGetField', obj, 'uddobject'));
catch exception
    throw(exception);
end