function setStruct = privateSetList(obj, varg1)
%PRIVATESETLIST Create the SET display.
%
%    PRIVATESETLIST(OBJ) creates the SET display for SET(OBJ).
%
%    PRIVATESETLIST(OBJ, PROP) creates the SET display for
%    SET(OBJ, PROP).
%

%    MP 4-19-98
%    Copyright 1998-2011 The MathWorks, Inc.
%    $Revision: 1.9.2.10 $  $Date: 2011/10/31 06:07:12 $

%    PRIVATESETLIST is a helper function for @daqdevice\set and
%    @daqchild\set.

% Initialize variables
nout = nargout;
setStruct = '';

switch nargin
case 1 % SET( OBJ )
   
   if nargout == 0 && (length(obj)>1)
      error('daq:privatesetlist:novectors',...
          'Vector of objects not permitted for SET(OBJ) with no left hand side.')
   end
   
   % Create the cell array of structures of object PV pairs.
   x = struct(obj);
   output = cell(length(obj),1);
   for i = 1:length(obj)
     list = set(x.uddobject(i));

     % Sort the fields alphabetically
     fields = fieldnames(list);
     [sortedFields, index] = sort(lower(fields));
     for j=1:length(sortedFields),
        sortedList.( fields{index(j)} ) = list.( fields{index(j)} );
     end
     output{i} = sortedList;
   end
   
   if nout == 1
      % Return structure of settable properties.
      if length(obj) == 1
         setStruct = output{:};
      else
         setStruct = output;
      end
   elseif nout == 0
      % Create display of settable properties.
      localSetDisplay(obj,output{:});
   end
   return;
case 2 % SET( OBJ, [Cell | Structure | 'Property'] )
   % set(obj, {'Property'}) - should error.
   if iscell(varg1)
      error('daq:privatesetlist:invalidpv',...
          'Invalid parameter/value pair arguments.');
   elseif ischar(varg1) 
      % set(obj, 'Property')
      % obj must be 1-by-1 otherwise produce an error.
      if length(obj) ~= 1
         error('daq:privatesetlist:scalarreq',...
             'Object array must be a scalar when using SET to retrieve information.')
      end
      % Obtain the list of settable values.
      x = struct(obj);
      output = set(x.uddobject,varg1);
      
      % Create appropriate display. Display is dependent upon if an output
      % variable was specified and if the property has a list of values.
      
      % Determine if the property (varg1) is read-only.  This is needed so that
      % a different message can be returned indicating that it is a read-only 
      % property.
      [readonly,prop] = daqgate('privatereadonly', obj, varg1);
      
      % Error if readonly.
      if readonly
         error('daq:privatesetlist:cantsetreadonly',...
             'Attempt to modify read-only property: ''%s''.',prop);
      end
      
      % Either return an empty cell array or a message indicating that
      % the property does not have a fixed set of values depending on the
      % number of output variables.
      if isempty(output)
         if nout == 1
            % Return empty cell array
            setStruct = output;
         elseif nout == 0
            if ~isempty(strfind([prop ' '], 'Fcn ')) % ends in 'Fcn'
                fprintf('string -or- function handle -or- cell array\n');                  
            else
                fprintf(['The ''' prop ''' property does not have a fixed ',...
                         'set of property values.\n']);
            end
         end
      else
         if nout == 1
            % Return cell array of possible values for specified property.
            setStruct = output;
         elseif nout == 0
            % Create the bracketed list: [ {Off} | On ]
            str = localCreateList(obj, output, varg1);
            fprintf(['[' str ']\n']);
         end
      end
      return;
   end
end

% **********************************************************************
% Create the display for SET(OBJ)
function localSetDisplay(obj,output)

% Obtain a list of object fields.
fields = fieldnames(output);
values = struct2cell(output);

% Store device specific properties in DEVICEPROPS.
% Only check the property names that are associated with set
x = struct(obj);
propinfovalues = propinfo(x.uddobject,fields);
deviceprops = {};

% Loop through the fields to determine the string that will be
% displayed.  If the property does not have a list of settable
% values display the property name only.  If the property does 
% have a list of settable values create the bracketed expression
% with localCreateList and display it.  If the property is device
% specific add the correct display to the deviceprops cell array.
for i = 1:length(fields)
   if isempty(values{i})
      if propinfovalues{i}.DeviceSpecific,
         deviceprops = {deviceprops{:} sprintf('        %s\n', fields{i})};
      elseif ~isempty(strfind( [fields{i} ' '], 'Fcn ' )) % ends in 'Fcn'
         fprintf('        %s: string -or- function handle -or- cell array\n', fields{i} );
      else
         fprintf('        %s\n', fields{i});
      end
   else
      str = localCreateList(obj, values{i}, fields{i});
      if propinfovalues{i}.DeviceSpecific,
         deviceprops = {deviceprops{:} sprintf('        %s: [%s]\n',fields{i},str)};
      else
         fprintf('        %s: [%s]\n', fields{i}, str);
      end
   end
end

% Create a blank line after the property value listing.
fprintf('\n');

% Device specific properties are displayed if they exist.
if ~isempty(deviceprops)
   % Determine adaptor.
   if isa(obj,'daqchild'),
      parent = get(obj,'Parent');
   else
      parent = obj;
   end
   objinfo = daqhwinfo(parent);
   
   % Create device specific heading.
   fprintf(['        ' upper(objinfo.AdaptorName) ' specific properties:\n']);
   
   % Display device specific properties.
   for i=1:length(deviceprops),
      fprintf(deviceprops{i})
   end
   
   % Create a blank line after the device specific property value listing.
   fprintf('\n');
end

% *************************************************************************
% Create the list of property values for the SET(OBJ, PROP) display.
function str = localCreateList(obj,output,prop)

% Convert the output cell array {'Off';'On'} to a list that can
% be bracketed: Off | On
str = '';
for i = 1:length(output)
   str = [str ' ' output{i} ' |']; %#ok<AGROW>
end
% Remove the trailing pipe (|).
str = str(1:end-1);

% Obtain the default value.
[oldvalue, defaultvalue] = localGetDefault(obj,prop);

% Place braces around the default value.
str = strrep(str, oldvalue, defaultvalue);


% *******************************************************************
% Obtain the default value for the property.
function [old, new] = localGetDefault(obj,prop)

% Get the property information for the specified property.
propinfovalue = propinfo(obj,prop);

% Determine the default value and add braces to the defaultvalue string.
old = propinfovalue.DefaultValue;
if ~isempty(old)
   new = ['{' old '}'];
else
   new = '';
   old = '';
end	

% Surround the strings with spaces to prevent properties with identical
% substrings from being modified. For example LoggingMode has Memory and
% Disk&Memory with the desired result being {Memory} and not Disk&{Memory}.
% Another example is InputType which can have Differential and
% PseudoDifferential.
old = [' ' old ' '];
new = [' ' new ' '];
