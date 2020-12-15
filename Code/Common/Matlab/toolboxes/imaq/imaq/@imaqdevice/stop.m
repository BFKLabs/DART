function stop(obj, event)
% STOP Stop video input object running and logging. 
%
%    STOP(OBJ) halts an acquisition associated with video input object
%    OBJ. OBJ can be either a single or an array of video input objects.
%
%    When an acquisition is halted, OBJ performs the following operations:
%        1. Configures OBJ's Running property to 'Off'.
%        2. Configures OBJ's Logging property to 'Off' if needed.
%        3. Executes OBJ's StopFcn callback.
%    
%    OBJ can also stop running under one of the following conditions:
%        1. When the requested number of frames are acquired. This occurs 
%           when:
%                FramesAcquired = FramesPerTrigger * (TriggerRepeat + 1)
%           where FramesAcquired, FramesPerTrigger, and TriggerRepeat are
%           properties of OBJ.
%        2. A runtime error occurs.
%        3. OBJ's Timeout value is reached.
% 
%    The Stop event is recorded in OBJ's EventLog property.
% 
%    STOP may be called by a video input object's event callback e.g.,
%    obj.TimerFcn = {'stop'};
% 
%    See also IMAQHELP, IMAQDEVICE/START, IMAQDEVICE/TRIGGER, 
%             IMAQDEVICE/PROPINFO.

%    CP 9-01-01
%    Copyright 2001-2010 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'imaqdevice')
    error(message('imaq:stop:invalidType'));
elseif ( (length(obj) == 1) && ~isvalid(obj) )
    error(message('imaq:stop:invalidOBJ'));
elseif ~all(isvalid(obj))
    warning(message('imaq:stop:invalidOBJArray'));
end

% Verify the second input is the event structure.
if nargin == 2
   if ~(isfield(event, 'Type') && isfield(event, 'Data'))
      error(nargchk(1, 1, nargin, 'struct'));
   end
end

% Initialize variables.
errorOccurred = false;
uddObjects = imaqgate('privateGetField', obj, 'uddobject');

% Call stop on each UDD object.  Keep looping even 
% if one of the objects could not be opened.  
for i=1:length(uddObjects),
    % If the object is not valid, then just skip it.
    if ~ishandle(uddObjects(i));
        continue;
    end
    
   try
      stop(uddObjects(i));
   catch stopException
   	  errorOccurred = true;	    
   end   
end   

% Report error if one occurred.
if errorOccurred
    if length(uddObjects) == 1
		throw(stopException);
    else
        warnState = warning('backtrace', 'off');
        oc = onCleanup(@() warning(warnState));
        warning(message('imaq:stop:noStop'));
        clear('oc');
    end
end
