function mobjects = privateUDDToMATLAB(uddobjects)
%PRIVATEUDDTOMATLAB Convert UDD objects to their appropriate MATLAB object type.
%
%    MOBJECTS = PRIVATEUDDTOMATLAB(UDDOBJECTS) converts the vector of UDD
%    objects, UDDOBJECTS, to a vector of the appropriate MATLAB objects.
%    If UDDOBJECT is not a valid daq UDD object, it will be returned without
%    modifications. 
%

%    CP 9-01-01
%    Copyright 2001-2008 The MathWorks, Inc.
%    $Revision: 1.1.6.2 $  $Date: 2008/08/20 22:53:46 $

% For cell arrays...
% Needed because GET(UDDOBJ,{'Prop1','Prop2'}) returns a cell array.
if ( iscell(uddobjects) )
    % Convert each cell element
    [m,n] = size(uddobjects);
    mobjects = cell(m,n);
    for i=1:m
       for j=1:n
          mobjects{i,j} = privateUDDToMATLAB(uddobjects{i,j});
       end
    end
elseif ( isstruct(uddobjects) )
    % For structures...
    % Needed because GET(UDDOBJ) returns a structure.

    % For each structure
    for s = 1:length(uddobjects)
       % For each field in the structure
       fields = fieldnames(uddobjects(s));
       for f = 1:length(fields)
           % Convert the field in place to keep the same array dimension.
           % Recurse because propinfo(OBJ) returns structure of structures.
           fieldvalue = privateUDDToMATLAB( uddobjects(s).(fields{f}) );
           uddobjects(s).(fields{f}) = fieldvalue;
       end
    end
    mobjects = uddobjects;
else
    mobjects = localUDDToMATLAB(uddobjects);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper function that converts 1xN or Nx1 vectors of uddobjects 
function mobjects = localUDDToMATLAB(uddobjects)

% If the incoming value is not really a UDD object(s), return unchanged. 
if ( isempty(uddobjects) || ~localIsHandle(uddobjects) )
    mobjects = uddobjects;
    return;
end
    
try
   % Get OOPS class name(s).
   classname = get(uddobjects, 'OOPSType');
   if ( ~iscell(classname) )
       classname = {classname};
   end
   
   % Construct M object to wrap uddobject.
   
   % If all of the objects are the same type.
   if ( all(strcmp(classname, classname{1})) )
       % Save time by just constructing one OOPS object.
       mobjects = feval(classname{1}, uddobjects);
      
   % If the objects are different types.
   else   
      mobjects = [];
      [m,n] = size( uddobjects );
      for i=1:length( uddobjects )
         if ( n > 1 ) % Horizontal vector
            mobjects = [ mobjects feval(classname{i}, uddobjects(i))];
         else % Vertical vector
            mobjects = [ mobjects; feval(classname{i}, uddobjects(i))];
         end
      end
   end
catch
   % Mostly likely that get('OOPSType') failed because its not a daq UDD object.
   mobjects = uddobjects;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper function that determines if objects are uddobjects
function result = localIsHandle(uddobjects)

% G478429: if it is a java object, it's a handle
if isjava(uddobjects)
    result = true;
    return
end

% Make sure we're dealing with a vector.
if ( ~isvector(uddobjects) )
    uddobjects = uddobjects(:);
end    

% If any non-handles.
if ( any(~ishandle(uddobjects)) )
    result = false;
    return;
end

% ishandle returns true for double values of 0 so
% we also must also test for 0.
if ( any(uddobjects == zeros) )
    result = false;
    return;
end

result = true;
