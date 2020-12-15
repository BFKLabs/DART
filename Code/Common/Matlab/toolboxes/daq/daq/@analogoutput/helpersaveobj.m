function obj = helpersaveobj(obj)
%HELPERSAVEOBJ Helper function to SAVEOBJ.
%
%    B = HELPERSAVEOBJ(OBJ) is a helper function for SAVEOBJ which 
%    is a save filter for data acquisition objects.
%
%    See also DAQ/PRIVATE/SAVE, SAVEOBJ.
%

%    MP 9-23-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.8.2.6 $  $Date: 2008/06/16 16:34:46 $

% If the object is invalid store nothing, warn and return.
if ~all(isvalid(obj))
   obj.daqdevice = getsetstore(obj.daqdevice,[]);
   
   % Set the warning to not use a backtrace.
   s = warning('off', 'backtrace');
   warning('daq:saveobj:invalidobject', 'An invalid object is being saved.');
   % Restore the warning state.
   warning(s);
   
   return;   
end

% Obtain the information needed for storing.
% store_info{1} - property values of the device object
%                (minus the Channel property).
% store_info{2} - property values of the child objects
%                (minus the Parent property).
% store_info{3} - Unique Handle
% store_info{4} - a cell array of the adaptor and HWID.
try
   store_info = daqgate('privatesavecell', obj);
catch e
   error('daq:saveobj:unexpected', e.message);
end

% Clear out uddobject field and replace with a sequence from 1 to length(obj).
% maintain same dimensions as obj. This is needed to avoid UDD attempting
% to serialize the udd object, and so the correct dimensions of obj can
% be restored on load.
indices = 1:length(obj);
indices = reshape(indices,size(obj));
obj.uddobject = indices;

% Append the indices onto the store information.
store_info = {store_info obj.uddobject};

% Save the information to the store field of daqdevice object.
% GETSETSTORE is used to access the parent object's (daqdevice object)
% store field since a parent's fields are not accessible in a child 
% object's methods.
obj.daqdevice = getsetstore(obj.daqdevice,store_info);

