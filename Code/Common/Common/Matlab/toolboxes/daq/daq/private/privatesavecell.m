function [store_info, child] = privatesavecell(objs)
%PRIVATESAVECELL Obtain information to be stored before saving object.
%
%    STORE_INFO = PRIVATESAVECELL(OBJ) obtains the information from the 
%    object, OBJ, that needs to be stored in the parent object's 
%    store field.
%

%    PRIVATESAVECELL is a helper function for @analoginput\saveobj,
%    @analogoutput\saveobj, @aichannel\saveobj, @aochannel\saveobj.
%

%    MP 6-08-98
%    Copyright 1998-2005 The MathWorks, Inc.
%    $Revision: 1.10.2.7 $  $Date: 2007/06/18 22:04:00 $

uddobjs = daqgetfield(objs, 'uddobject');
info = daqgetfield(objs, 'info');

% Adaptor names used by special case code
nidaqAdaptorName = 'nidaq';
nidaqmxAdaptorName = 'nidaqmx';

for i = 1:length(objs)
   obj = objs(i);
   uddobj = uddobjs(i);
   
   % Determine the child object's name (Channel or Line).
   child_name = info(i).child;
   
   % Obtain the child objects 
   child = get(obj, child_name);
   
   % Get the parent property information and remove the child field (Channel/Line).
   parent_prop = get(obj);
   parent_prop = rmfield(parent_prop, child_name);
   
   % If the TriggerChannel property exists and it is set to a channel, save the
   % index of the channel rather than the actual channel.
   if isfield(parent_prop, 'TriggerChannel') && ~isempty(parent_prop.TriggerChannel)
      parent_prop.TriggerChannel = get(parent_prop.TriggerChannel, {'Index'});
   end
   
   % Get child property information and remove the Parent field.
   child_prop = get(child);
   if ~isempty(child_prop)
      child_prop = rmfield(child_prop, 'Parent');
   end
   
   % Get the unique handle property value of the object
   guid = get(obj, 'Handle');
   
   % Get the adaptor and ID for the object.
   hwinfo = daqhwinfo( obj );
   adaptor = hwinfo.AdaptorName;
   hwid = hwinfo.ID;
   
    % Geck 281433 & 284943:  In order to make NIDAQmx and NIDAQ adaptors look like a
    % single adaptor, we handle nidaq specially
    if(strcmpi(adaptor,nidaqmxAdaptorName))
        adaptor = nidaqAdaptorName;
    end

   % Handle the special case of UserData which may contain nested objects.
   if isfield(parent_prop, 'UserData') && ~isempty(parent_prop.UserData)
      
      tempobj = get( obj, 'UserData');
      
      % UserData has not been saved yet for this object.
      if ~localIsSaved(uddobj,'UserData')
          
          % Mark it as saved now to prevent infinite recursion.
          localSetSaved(uddobj,'UserData'); 
          
          % Attempt to save/convert any objects in the UserData field.
          parent_prop.UserData = daqgate('privateSaveUserData', tempobj, false);
      else
          % UserData has already been saved. Clear any uddobject field to
          % avoid unwanted UDD saves.          
          parent_prop.UserData = daqgate('privateSaveUserData', tempobj, true);
      end
   end
   
   % Determine if any of the callback properties contain a Data Acquisition
   % object.
   parent_prop_field = fieldnames(parent_prop);
   parent_prop_value = struct2cell(parent_prop);
   for k = 1:length(parent_prop_field)
      callbackInfo = propinfo(obj, parent_prop_field{k});
      if strcmp(callbackInfo.Type, 'callback') && iscell(parent_prop_value{k})
         tempobj = get( obj, parent_prop_field{k} );
         if ~localIsSaved(uddobj,parent_prop_field{k})
             % The callback has not been saved yet for this object.
             localSetSaved(uddobj,parent_prop_field{k});
             parent_prop = setfield(parent_prop, parent_prop_field{k}, ...
                daqgate('privateSaveUserData', tempobj, false));
         else
             parent_prop = setfield(parent_prop, parent_prop_field{k}, ...
                daqgate('privateSaveUserData', tempobj, true));
         end
      end
   end
   
   % Combine the information into a cell array.
   store_info{i} = {parent_prop, child_prop, guid, {adaptor hwid}};
end
end

%
function savedFlag = localIsSaved( uddobj, propertyName )
    if ~ishandle(uddobj)
        % invalid object.
        savedFlag = false;
        return;
    end
    
    savedProp = uddobj.findprop('Saved');
    if ( isempty(savedProp) )
        % Saved property doesn't exist yet.
        savedFlag = false;
        return;
    end
    
    % If property name exists in list of saved items.
    savedItems = get( uddobj, 'Saved' );
    if any( strcmpi(  savedItems, propertyName ) )
        savedFlag =  true;
    else
        savedFlag = false;
    end
end

%
function localSetSaved( uddobj, propertyName )
    if ~ishandle(uddobj)
        % invalid object.
        return;
    end
    
    savedProp = uddobj.findprop('Saved');
    if ( isempty(savedProp) )
        % Saved property doesn't exist yet. Create it.
        prop = schema.prop(uddobj, 'Saved', 'MATLAB array');
        prop.Visible = 'off';
    end
    
    % If property name exists in list of save items.
    savedItems = get( uddobj, 'Saved' );
    if any( strcmpi(  savedItems, propertyName ) )
        % Already marked as saved.
        return;
    end
    
    % Add property to list of saved items.
    savedItems{length(savedItems)+1} = propertyName;
    set(uddobj, 'Saved', savedItems );
end

