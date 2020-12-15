function uddobjects = privateMATLABToUDD(mobjects)
%PRIVATEMATLABTOUDD Convert MATLAB OOPS objects to the underlying UDD
% objects.
%
%    UDDOBJECTS = PRIVATEMATLABTOUDD(MOBJECTS) converts the cell array,
%    structure, or vector of OOPS objects, MOBJECTS, to the appropriate 
%    UDD objects. If MOBJECT is not a valid daq object, it will be 
%    returned without modifications. 
%

%    DTL 7-01-04
%    Copyright 2004 The MathWorks, Inc.
%    $Revision: 1.1.6.1 $  $Date: 2004/12/01 19:48:01 $

% For cell arrays...
% Needed because SET(OBJ,PN,PV) can take a cell array of values (PV).
% In addition, DAQFIND(PV) can take a cell array of property/value pairs.
if ( iscell(mobjects) )
    % Recursively convert each cell element
    [m,n] = size(mobjects);
    uddobjects = cell(m,n);
    for i=1:m
       for j=1:n
          % recurse because daqfind allows cells of cells containing values
          uddobjects{i,j} = privateMATLABToUDD(mobjects{i,j});
       end
    end
elseif ( isstruct(mobjects) )
    % For structures...
    % Needed because SET(OBJ,S) can take a structure (S) of property/value pairs.
    % In addition, DAQFIND(S) can take a structure of property/value pairs.

    % For each structure
    for s = 1:length(mobjects)
       % For each field in the structure
       fields = fieldnames(mobjects(s));
       for f = 1:length(fields)
           % Convert the field in place to keep the same array dimension.
           fieldvalue = privateMATLABToUDD( mobjects(s).(fields{f}) );
           mobjects(s).(fields{f}) = fieldvalue;
       end
    end
    uddobjects = mobjects;
else
    uddobjects = localMATLABToUDD(mobjects);
end

% Helper function that converts 1xN or Nx1 vectors of mobjects 
function uddobjects = localMATLABToUDD(mobjects)

% If not a object, return unchanged.
if ( ~isobject(mobjects) )
    uddobjects = mobjects;
    return;
end

try
   % Get uddobject field from OOPS object.
   s = struct(mobjects);
   uddobjects = s.uddobject;
catch
   % Mostly likely that struct does not contain a 'uddobject' field.
   uddobjects = mobjects;
end


