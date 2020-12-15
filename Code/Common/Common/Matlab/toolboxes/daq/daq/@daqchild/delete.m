function delete(obj)
%DELETE Remove data acquisition objects from the engine.
%
%    DELETE(OBJ) removes object, OBJ, from the data acquisition engine.
%    If any channels or lines are associated with OBJ, they are also 
%    deleted.  OBJ can be either a device array or a channel/line.
%
%    If OBJ is the last object accessing the identified hardware, the
%    associated hardware driver and driver specific adaptor are closed 
%    and unloaded.
%
%    Using CLEAR removes OBJ from the workspace only.
%  
%    DELETE should be used at the end of a data acquisition session.
%
%    If OBJ is running, DELETE(OBJ) will delete OBJ and a warning 
%    will be issued.  If OBJ is running and logging/sending, DELETE(OBJ)
%    will not delete OBJ and an error will be returned.
%
%    If multiple references to a data acquisition object exist in the 
%    workspace, deleting one reference will invalidate the remaining 
%    references.  These remaining references should be cleared from 
%    the workspace.
%
%    Example:
%      ai = analoginput('winsound');
%      aiCopy = ai;
%      delete(ai)  % Removes ai from the data acquisition engine.
%                  % aiCopy is now an invalid object.
%
%    See also DAQHELP, DAQRESET.
%

%    DTL 9-1-2004
%    Copyright 1998-2013 The MathWorks, Inc.
%    $Revision: 1.12.2.7 $  $Date: 2013/05/13 22:13:10 $

% Initialize variables.
chanstruct = struct(obj);
uddobjs = chanstruct.uddobject;

% If the handle is valid delete the object.  The validity needs to be 
% checked for the case: delete([chan1 chan1 chan2]);  After deleting 
% the first element in the array, the second element is invalid and 
% calling delete on it produces an error.
% We go in reverse because some devices only allow the last channel to be
% deleted.
for i = length(uddobjs):-1:1
   try
       % If valid. NOTE can't use isvalid(obj(i)) because of SUBSREF.
       if ( ishandle(uddobjs(i)) && uddobjs(i)~=0 )
           delete(uddobjs(i)); 	
       end
   catch e
       error('daq:delete:unexpected', e.message);
   end
end


