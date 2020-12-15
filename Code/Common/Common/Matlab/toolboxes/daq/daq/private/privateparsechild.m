function [prop1, index] = privateparsechild(obj,Struct)
%PRIVATEPARSECHILD Parse input for daqchild objects.
%
%    [PROP1, INDEX] = PRIVATEPARSECHILD(STRUCT) parses the input
%    structure, STRUCT, into property names (PROP1) and the INDEX.
%   
%    For example, obj(2).ChannelName would parse into
%    INDEX = 2, PROP1 = 'ChannelName'.
%

%    PRIVATEPARSECHILD is a helper function for @daqchild\subsref and
%    @daqchild\subsasgn.

%    MP 6-03-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.9.2.5 $  $Date: 2008/06/16 16:36:05 $

% Initialize variables
StructL = length(Struct);
index = 1;
prop1 = '';

% Define possible error messages
error1ID = 'daq:privateparsechild:cellRefFromNonCell';
error1 = 'Cell contents reference from a non-cell array object.';
error2ID = 'daq:privateparsechild:inconsistParens';
error2 = 'Inconsistently placed ''()'' in subscript expression.';
error3ID = 'daq:privateparsechild:unkSubsRefType';
error3 = 'Unknown type: %s.';
error4ID = 'daq:privateparsechild:badsubscript'; %#ok<NASGU>
error4 = 'Index exceeds matrix dimensions.'; %#ok<NASGU>

% Parse the input structure, Struct, into the prop1 and index  
% variables.  Subsref syntax: obj(index).prop1 and obj.prop1
switch Struct(1).type
case '.'
   % chan.SensorRange/obj.prop1
   prop1 = Struct(1).subs;   
case '()'
   % chan(1:3)/obj(index)
   index = Struct(1).subs;
   if length(index) == 1 && isempty(index{1})
      % return empty in index if it's empty.
      index = [];
      return;
   end 
   if length(index) > 1
      try
        index = localCheckIndex(obj, index);
      catch e
         return;
      end
   end
   % If the first Struct type is (), obtain the property name
   % if it was given - (chan(1:3).SensorRange/obj(index).prop1).
   if StructL > 1
      switch Struct(2).type
      case '.'
         prop1 = Struct(2).subs;
      case '()'
         error(error2ID,error2);
      case '{}'
         error(error1ID,error1);
      otherwise
         error(error3ID,error3,Struct(2).type);
      end
   end
case '{}'
         error(error1ID,error1);
otherwise
	 error(error3ID,error3,Struct(2).type);
end

% ********************************************************************
% Check the multiple indices.
function index = localCheckIndex(obj, index)

% Initialize variables.
[m,n] = size(obj);

% Compare the first index to the number of rows.
if max(index{1}) > m || min(index{1}) < 1 
   if ~strcmp(index{1}, ':') 
      error(error4ID,error4);
   end
end

% Compare the second index to the number of columns.
if max(index{2}) > n || min(index{2}) < 1 
   if ~strcmp(index{2}, ':')
      error(error4ID,error4);
   end
end

% If any of the indices are empty then need to return empty brackets.
if isempty(index{1}) || isempty(index{2})
   % return empty in index if it's empty.
   index = [];
   return;
end

% If obj is a row vector, replace index{1} with index{2} so only one 
% element of index is used and it doesn't have to be checked.
if m == 1
   index{1} = index{2};
end

% For the remaining indices, it is only valid if the index is 1 or ':'.
% If it is empty, an empty matrix should be returned.
for i = 3:length(index)
   if ~isempty(index{i}) && length(index{i}) ~= 1
      error(error4ID,error4);
   end
   if ~isempty(index{i}) && ~(strcmp(index{i}, ':') || all(index{i} == 1)) 
      error(error4ID,error4);
   end
end

for i = 3:length(index)
   if isempty(index{i})
      % return empty in index if it's empty.
      index = [];
      return;
   end
end

