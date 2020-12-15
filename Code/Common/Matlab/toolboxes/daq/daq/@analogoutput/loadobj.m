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
%    $Revision: 1.11.2.6 $  $Date: 2008/06/16 16:34:49 $

% Get the information that was stored during SAVEOBJ in Daqdevice's
% store field. 
info = getsetstore(B.daqdevice); 
if ~isempty(info)
   propinfo = info{1};
else
   propinfo = {};
end
   
% If info is empty an invalid object was stored and an invalid
% object is created and returned.
if isempty(propinfo)  
   obj = analogoutput;
   % It is possible that info will be an empty cell array.  This occurs if 
   % the object saved UserData is another data acquisition object.  If this 
   % is the case, a warning should not be displayed.
   if isnumeric(propinfo)
      % Set the warning to not use a backtrace.
      s = warning('off', 'backtrace');
      warning('daq:loadobj:invalidobject', 'An invalid object is being loaded.');
      % Restore the warning state.
      warning(s);
   end
   return;
end

for j = 1:length(propinfo)
   % Initialize variables.
   objinfo = propinfo{j};
   created = 0;
   objtype = lower(objinfo{1}.Type);
   objtype(find(objtype == ' ')) = []; %#ok<FNDSB>
   
   % Extract the unique handle from the store variable, objinfo.
   guid = objinfo{3};
   
   % Obtain a cell array of AnalogInput, AnalogOutput and DigitalIO objects.
   basevar = daqfind;
   for i = 1:length(basevar)
      % If the object is an AnalogInput compare the creation time.
      tempobj = get(basevar, i);
      if isa(tempobj, objtype)
         if (guid == get(tempobj, 'Handle'))
            % If the guid's are equal the objects are pointing to 
            % the same thing in the engine.  privateExistParent compares
            % the property values of the two objects and makes them the 
            % same as the object that is being loaded.
            try
               device{j} = daqgate('privateExistParent',objinfo, tempobj); %#ok<AGROW>
               created = 1;
            catch e
               error('daq:loadobj:unexpected', e.message);
            end
            if created
               break;
            end
         end
      end
   end
   
   % The object does not already exist in the MATLAB workspace so it needs
   % to be created.
   if ~created
      try
         device{j} = daqgate('privatecreateobj', objinfo); %#ok<AGROW>
      catch e
         error('daq:loadobj:unexpected', e.message);
      end
   end
end

% Construct the output.
obj = [];
for i = 1:length(propinfo)
   obj = [obj device{i}]; %#ok<AGROW>
end

% If the sizes are not equal then transpose the device array.
if size(info{2}) ~= size(obj)
   obj = obj';
end
