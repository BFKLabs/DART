function obj = saveobj(obj)
%SAVEOBJ Save filter for data acquisition objects.
%
%    B = SAVEOBJ(OBJ) is called by SAVE when a data acquisition object is
%    saved to a .MAT file. The return value B is subsequently used by SAVE  
%    to populate the .MAT file.  
%
%    SAVEOBJ will be separately invoked for each object to be saved.
% 
%    See also DAQ/PRIVATE/SAVE, LOADOBJ.
%

%    MP 4-17-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.6.2.7 $  $Date: 2008/06/16 16:35:52 $

% If the object is invalid store nothing, warn and return.
if ~all(isvalid(obj))
   obj.daqchild = getsetstore(obj.daqchild,[]);
   
   % Set the warning to not use a backtrace.
   s = warning('off', 'backtrace');
   warning('daq:saveobj:invalidobject', 'An invalid object is being saved.');
   % Restore the warning state.
   warning(s);
   
   return;
end

% Get the parent object.
% Then obtain the information needed for storing.
% store_info{1} - property values of the device object
%                (minus the Line property).
% store_info{2} - property values of the child objects
%                (minus the Parent property).
% store_info{3} - Creation Time
% store_info{4} - a cell array of the adaptor and HWID.
% children      - the actual children saved.
try
   % Get the parent.
   % NOTE: Old DAQ code allowed more than one object but returned the
   % parent of the last object. Duplicate this behavior.
   parent = get(obj,'parent');
   if ( length(parent) > 1 )
      parent = parent{length(parent)};
   end
   [store_info, children] = daqgate('privatesavecell', parent);
catch e
   error('daq:saveobj:unexpected', e.message);
end

% Get the handles to the children that are being saved.
% For compatibility with the uddobject field, get them as an Nx1 array.
saved_handles = get( obj.uddobject, 'Handle' );
if (iscell(saved_handles)) 
    % More than one handle, convert to array of proper dimensions.
    saved_handles = cell2mat(saved_handles);
    saved_handles = reshape(saved_handles,size(obj));
end

% Clear out uddobject field and replace with the handles.
% This is needed to stop UDD from attempting to serialize the udd object. 
% The handles are used on load so that the correct children can be restored
% and the correct array dimensions can be restored.
obj.uddobject = saved_handles;

% Get the handles to all the children on the parent.
% For backward compatibility, get them as a 1x1 cell array of
% an Nx1 array.
chan_handles = get( children, 'Handle' );
if (iscell(chan_handles))
    chan_handles = cell2mat(chan_handles);
end
if ~iscell(chan_handles)
   chan_handles = {chan_handles};
end

% Add chan_handles to the store_info cell array.
store_info{2} = chan_handles;

% Save the information to the store field of the daqchild object.
% GETSETSTORE is used to access the parent object's (daqchild object)
% store field since a parent's fields are not accessible in a child 
% object's methods.
obj.daqchild = getsetstore(obj.daqchild,store_info);


