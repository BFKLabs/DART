function [out, prop] = privatereadonly(obj, varargin)
%PRIVATEREADONLY Return read-only properties of data acquisition object.
%
%    OUT = PRIVATEREADONLY(OBJ) returns a cell array, OUT, which 
%    contains the read-only property names for the data acquisition  
%    object, OBJ.
%
%    [OUT, FPROP] = PRIVATEREADONLY(OBJ, PROP) determines if the 
%    specified property, PROP, is a read-only property.  OUT = 1
%    if PROP is a read-only property.  OUT = 0 if PROP is not
%    a read-only property.  FPROP is a string containing the full
%    property name (for property completion).
%

%    PRIVATEREADONLY is a helper function for @analoginput\loadobj,
%    @analogoutput\loadobj, @aichannel\loadobj, @aochannel\loadobj,
%    @daqdevice\set, @daqchild\set.
%

%    MP 6-10-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.9.2.6 $  $Date: 2008/06/16 16:36:07 $

switch nargin
case 1
   % A helper function for @analoginput\loadobj,@analogoutput\loadobj,
   % @aichannel\loadobj, @aochannel\loadobj.
   
   % Determine the read-only properties.
   x = struct(obj);
   value = propinfo(x.uddobject);
   names = fieldnames(value);
   
   % Convert 1-by-1 struct to a number_of_prop-by-1 cell array.
   value1 = struct2cell(value);
   
   % Convert the number_of_prop-by-1 cell array to a 1-by-number_of_prop
   % structure.
   h=[value1{:}];
   
   % Find the read-only properties.
   out = names(find(strcmp({h.ReadOnly},'always'))); %#ok<FNDSB>
case 2
   % A helper function for @daqdevice\set, @daqchild\set.
   
   % Initialize variables.
   prop = varargin{1};
   x = struct(obj);
   
   % Get a list of valid properties.
   try
      hget = get(x.uddobject);
   catch e
      error('daq:readonly:unexpected', e.message)
   end
   % Get the property names from the output of GET.
   getprop = fieldnames(hget);
   
   % Get sorted lists in both upper and lower case.
   [getpropsorted, indices] = sort(lower(getprop));
   getprop = getprop(indices);
    
   % Determine if the specified property is read-only.
   propinfovalue = propinfo(x.uddobject, prop);
   out = strcmp(propinfovalue.ReadOnly,'always');
   
   % Handle property completion.  Always use the first property listed
   % if multiple values are returned - set(ai, 'Logging')
   value = find(strncmpi(prop, getpropsorted, length(prop)));
   if ~isempty(value)
      prop = getprop{value(1)};
   end
end


































