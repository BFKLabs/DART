function output = privateFind(varargin)
%DAQFIND Find data acquisition objects with specified property values.
%
%    OUT = DAQFIND returns an array, OUT, of any analog input, analog
%    output or digital I/O objects currently existing in the data acquisition
%    engine.
%
%    OUT = DAQFIND('P1', V1, 'P2', V2,...) returns a cell array, OUT, of
%    objects, channels or lines whose property values match those passed
%    as PV pairs, P1, V1, P2, V2,... The PV pairs can be specified as a
%    cell array.
%
%    OUT = DAQFIND(S) returns a cell array, OUT, of objects, channels or
%    lines whose property values match those defined in structure S whose
%    field names are object property names and the field values are the
%    requested property values.
%
%    OUT = DAQFIND(OBJ, 'P1', V1, 'P2', V2,...) restricts the search for
%    matching PV pairs to the objects listed in OBJ and the channels or
%    lines contained by them.  OBJ can be an array or cell array of objects.
%
%    Note that it is permissible to use PV string pairs, structures,
%    and PV cell array pairs in the same call to DAQFIND.
%
%    In any given call to DAQFIND, only device object properties or
%    channel/line properties can be specified.
%
%    When a property value is specified, it must use the same format as
%    GET returns.  For example, if GET returns the ChannelName as 'Left',
%    DAQFIND will not find an object with a ChannelName property value of
%    'left'.  However, properties which have an enumerated list data type,
%    will not be case sensitive when searching for property values.  For
%    example, DAQFIND will find an object with a Running property value
%    of 'On' or 'on'.  The data type of a property can be determined with
%    PROPINFO's Constraint field.
%
%    Example:
%      ai = analoginput('winsound');
%      addchannel(ai, [1 2], {'Left', 'Right'});
%      out = daqfind('Units', 'Volts')
%      out = daqfind({'ChannelName', 'Units'}, {'Left', 'Volts'})
%
%    See also PROPINFO, DAQDEVICE/GET.
%

%   DTL 7-1-04
%   Copyright 2004-2008 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2008/06/16 16:36:01 $

% First argument may be a cell array of objects. 
% For example: DAQFIND({obj1 obj2},'Type','Analog Input')
% Convert it to array of unique objects and use the object version of daqfind.
if ( nargin > 0 )
   obj = varargin{1};
   % If cell array of objects.
   if ( iscell(obj) && isobject(obj{1}) )
       % First attempt to convert the cell array to a matrix.
       try
           obj = [obj{:}];
       catch
           % Catch any concatenation failure.
           % This will happen when trying to concat device
           % objects with child objects or when trying to 
           % concat child objects from different devices.
       end
       
       % If the concatenation worked, use the object version of daqfind.
       if ( ~iscell(obj) )
           output = daqfind(obj, varargin{2:end});
       else  
           % Otherwise process each entry in the cell individually.
           output = cell(1,0);
           for i=1:length(obj)
               % Make sure we are dealing with an object, before calling
               % the object version of daqfind.
               if ( ~isobject(obj{i}) )
                   error('daq:daqfind:invalidarg','Invalid input argument passed to DAQFIND.');
               end
               result = daqfind(obj{i}, varargin{2:end});
                  
               % Concatenate result to the output cell array
               noutput = length(output);
               if ( noutput == 0 )
                   output = result;
               else
                   for j = 1:length(result)
                       output{noutput+j,1} = result{j};
                   end
               end
           end 
       end    
       
       % Remove any duplicates from the results
       output = localRemoveDuplicates(output);
       return;
   elseif ( isobject(obj) )
       % This occurs when we pass something other than a DAQ object to
       % the object version of daqfind: DAQFIND(vi,'Tag','videoinput').
       error('daq:daqfind:invalidarg','Invalid input argument passed to DAQFIND.');
   end
end

% Error checking.  Since this is the non-object method of DAQFIND,
% parameters must be PV pairs.  However, it is possible to specify the PV
% pairs as one or more structs or cell arrays so those need to be accounted for.
curArg = 1;
while (curArg <= nargin)
    if ( isstruct(varargin{curArg}) || iscell(varargin{curArg}))
        % Since a struct/cell only requires one parameter, move to the next
        % parameter on the next pass through the loop.
        curArg = curArg + 1;
    else
        % If this is the last argument and it is not a struct/cell, that is an
        % error.
        if (nargin == curArg)
            error('daq:daqfind:pvpair', 'Incomplete property-value pair.');
        end
        % On the next pass through the loop, move to the argument after the
        % "Value" part of the PV pair.
        curArg = curArg + 2;
    end
end
            
% Initialize.
output = [];

% Locate our package.
daqpck = findpackage('daq');
if isempty(daqpck)
    return;
end

% Find all the top-level objects. 
daqdb = daqpck.DefaultDatabase;
out = find(daqdb,'-depth',1);
if isempty(out)
    % No objects exist
	return;
end

% Remove the database handle, if present. It should always be 
% the first element, but check in case this changes.
out = out(daqdb~=out);
if isempty(out)
    % No objects exist
	return;
else
    % Convert to MATLAB objects.
    output = privateUDDToMATLAB( out );
end

% Search for a subset of PV pairs if provided.
if (nargin>0)
    % Use the object version of daqfind.
    output = daqfind(output, varargin{:});
end

% Remove any duplicate from the cell array
function output = localRemoveDuplicates(input)
    output{1} = input{1};
    for iInput = 1:length(input)
        % Test if the each value is already in the output cell.
        duplicate = false;
        for iOutput = 1:length(output)
            if ( eq( input{iInput}, output{iOutput} ) )
                duplicate = true;
                break;
            end
        end
        
        % Add if not a duplicate.
        if ( ~duplicate )
            output{length(output)+1,1} = input{iInput};
        end
    end
