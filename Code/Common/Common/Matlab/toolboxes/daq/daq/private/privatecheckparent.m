function out = privatecheckparent(varargin)
%PRIVATECHECKPARENT Determine if data acquisition objects have same parent.
%
%    OUT = PRIVATECHECKPARENT(OBJ1, OBJ2,...) determines if data
%    acquisition objects OBJ1, OBJ2,... have the same parent and are
%    valid.
%
%    OUT is 2 if the object is invalid.
%    OUT is 1 if the object's don't have the same parent.
%    OUT is 0 of the object's do have the same parent and are valid.
%
%    PRIVATECHECKPARENT is a helper function for HORZCAT and VERTCAT.
%

%    MP 6-03-98
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.11.2.6 $  $Date: 2005/06/17 20:20:05 $


% Initialize variables
out = 0;
uddobject=[];
chan = varargin{:};

% Obtain the handle of the parent of the first object passed.  Then compare 
% the remaining objects parent's handles to the first objects parent's handle.
for i = 1:length(chan)
   if ~isempty(chan{i})
      try
         if isvalid(chan{i})
            % Get parent.
            % NOTE: Old code called daqmex which allowed more than one
            % object but returned parent of the last object. Duplicate this
            % behavior.
            parent = get(chan{i},'Parent');
            if ( length(parent) > 1 )
               parent = parent{length(parent)};
            end
            
            if isempty(uddobject)
               x = struct(parent);
               uddobject = x.uddobject;
            end
         else
            % Object is invalid.
            out = 2;  
            return;
         end
      catch
         % An error occurred.
         out=1;   
         return;
      end
      
      % Determine if the objects have the same parent.
      x = struct(parent);
      if x.uddobject ~= uddobject
         out = 1;   
         return;
      end
   end
end