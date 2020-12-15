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
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.11.2.5 $  $Date: 2004/12/01 19:46:31 $

% Define a persistent variable to help with recursively linked objects
persistent objsSaved;

% Check to see if we have previously saved this object prior
if ~isempty(objsSaved)
	for i = 1:length(objsSaved)
		if isequal(objsSaved{i}, obj)
			% Detected that object has been previously saved
			% Break the recursive link
			obj = [];
			% Display a warning to the user
            bt = warning('query', 'backtrace');
            warning off backtrace;
			warning('daq:saveobj:recursive', ...
				'A recursive linking between objects has been found during the SAVE. \nAll objects have been saved, but the link has been removed.');			
            warning(bt);
            return;
		end
	end
end

% Object was not saved prior, add to recurssive list.
objsSaved{end+1} = obj;

% Error if the object is running.
uddobjs = daqgetfield(obj, 'uddobject');
for i = 1:length(uddobjs)
   if ishandle(uddobjs(i))
      if strcmp(lower(get(uddobjs(i), 'Running')), 'on')
         error('daq:saveobj:objectrunning', 'An object cannot be saved while it is running.\nUse STOP to stop the object running.');
      end
   end
end

% Call the helper function which does all the work.  This cannot be in the private
% directory since access to the object's fields are needed.
obj = helpersaveobj(obj);

% Reset the Saved flag to off so that the object and the object's
% UserData can be saved again.
localRemoveSaved();

% Object saved without recursive issue, remove from recursive list.
objsSaved(end) = [];

end

function localRemoveSaved
    allobj = daqfind;
    for i = 1:length(allobj)
        tempobj = get(allobj, i);
        tempudd = daqgetfield(tempobj,'uddobject');
        if ~isempty(tempudd) && ishandle(tempudd)
            delete(tempudd.findprop('Saved'));
        end
    end
end
