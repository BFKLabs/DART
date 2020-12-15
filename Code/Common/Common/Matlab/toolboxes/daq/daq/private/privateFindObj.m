function output = privateFindObj(obj, varargin)
%PRIVATEFINDOBJ Find data acquisition objects.
%
%    OUTPUT = DAQFIND(OBJ, 'P1', V1, 'P2', V2,...) returns a cell array, OUT, of
%    data acquisition objects whose property names and property values match 
%    those passed as parameter/value pairs, P1, V1, P2, V2. The parameter/value
%    pairs can be specified as a cell array. The search is restricted to the 
%    data acquisition objects listed in OBJ. OBJ can be an array of objects.
%
%    See also DAQDEVICE/DAQFIND.

%    DTL 6-28-04
%    Copyright 2004-2011 The MathWorks, Inc.
%    $Revision: 1.1.6.2 $  $Date: 2011/10/31 06:07:09 $

% Initialize first.
output = {};
children = {};

if ~isa(obj, 'daqdevice') && ~isa(obj, 'daqchild')
    error('daq:daqfind:invalidType', 'OBJ must be a valid data acquisition object.' );
end

validIndices = isvalid(obj);
if ~all(validIndices),
    % There are invalid objects.
    % Find all invalid indexes.
    inval_OBJ_indexes = find(isvalid(obj) == false);

    % Generate an error message specifying the index for the first invalid
    % object found.
    errStr = sprintf('%s %s.', 'OBJ contains an invalid data acquisition at index', num2str(inval_OBJ_indexes(1)));
    error('daq:daqfind:invalidOBJ', errStr);
else
    % Extract the valid objects.
    obj = obj(validIndices);  
    
    % Extract the unique objects (for backward compatibility with old DAQ).
    newobj = [obj(1)];
    for i=2:length(obj)
        % If the object is not in the new list
        if ( ~any( eq( obj(i), newobj ) ) )
               % Add it
               newobj = [ newobj obj(i) ];
        end
    end
    obj = newobj;
end

% Extract the UDD objects.
s = struct(obj);
uddobjects = s.uddobject;

% Convert any search parameters that are OOPS objects into UDD objects.
if ( ~isempty( varargin ) && isstruct( varargin{1} ) )
    params = privateMATLABToUDD( varargin{1} );
else
    params = privateMATLABToUDD( varargin );
end

% Do UDD search for the specified parameters. 
parent = find(uddobjects, params);

% If nothing found, return an empty cell array.
if isempty(parent)
    output = cell(0,0);
    return;
end
    
% Convert UDD objects to a cell array of MATLAB objects.
output = cell(length(parent),1);
for i=1:length(parent)
    output{i} = privateUDDToMATLAB( parent(i) );
end

