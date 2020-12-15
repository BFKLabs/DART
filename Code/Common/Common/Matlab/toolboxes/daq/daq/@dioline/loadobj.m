function obj = loadobj(B)
%LOADOBJ Load filter for data acquisition objects.
%
%    OBJ = LOADOBJ(B) is called by LOAD when a data acquisition object  
%    is loaded from a .MAT file. The return value, OBJ, is subsequently 
%    used by LOAD to populate the workspace.  
%
%    LOADOBJ will be separately invoked for each object in the .MAT file.
%
%    See also DAQ/PRIVATE/LOAD, SAVEOBJ.
%

%    MP 4-17-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.6.2.7 $  $Date: 2008/06/16 16:35:50 $

% Initialize parent variable
parent = [];

% Get the information that was stored during SAVEOBJ in daqchild's
% store field.  
info = getsetstore(B.daqchild);

% If info is empty an invalid object was stored and an invalid
% object is created and returned.
if isempty(info)
   obj = dioline;
   % It is possible that info will be an empty cell array.  This occurs
   % if the object saved UserData is another data acquisition object. 
   % If this is the case, a warning should not be displayed.
   if isnumeric(info)
      % Set the warning to not use a backtrace.
      s = warning('off', 'backtrace');
      warning('daq:loadobj:invalidobject', 'An invalid object is being loaded.');
      % Restore the warning state.
      warning(s);
   end
   return;
end

% Extract the unique handle of the parent and the handles of all the
% children originally on the parent. 
guid = info{1}{3};
chan_handles = info{2};

% Need to recreate the parent object so that the Parent field of the child
% object being loaded is correct.  All the child objects need to be
% created initially and then the handles of the object that is being loaded
% will be compared to the parent object's child objects and the correct
% children will be extracted.

% Obtain a cell array of DAQ objects.
basevar = daqfind;
for i = 1:length(basevar)
   % If the object is the correct parent type, compare the creation time.
   tempobj = get(basevar, i);
   if isa(tempobj, 'digitalio')
      if (guid == get(tempobj, 'Handle'))
         % If the guid's are equal the objects are pointing to 
         % the same thing in the engine.  privateExistParent compares
         % the property values of the two objects and makes them the 
         % same as the object that is being loaded.
         try
            parent = daqgate('privateExistParent',info{1}, tempobj);
         catch e
            error('daq:loadobj:unexpected', e.message);
         end;
         % The parent object has been created.  
         break;
      end
   end
end

% Construct the parent with all its children if it does not currently exist.
if isempty(parent)
   try
      parent = daqgate('privatecreateobj', info{1});
   catch e
      error('daq:loadobj:unexpected', e.message);
   end
end

% Get the handles of the children that were saved.
if ( B.version == 2.0 )
    saved_handles = B.uddobject;
else    
    saved_handles = B.handle;
end

% Return those children that were saved only.
obj = [];
for i = 1:length(saved_handles)
   index = find(saved_handles(i) == chan_handles{:});
   obj = [obj; parent.Line(index)]; %#ok<FNDSB,AGROW>
end

% If the sizes are not equal then transpose the child array.
if size(saved_handles) ~= size(obj)
   obj = obj';
end

   
