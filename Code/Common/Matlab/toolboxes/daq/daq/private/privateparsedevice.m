function [prop1, index1, prop2, index2] = privateparsedevice(Obj,Struct)
%PRIVATEPARSEDEVICE Parse input for daqdevice objects.
%
%    [PROP1, INDEX1, PROP2, INDEX2] = PRIVATEPARSEDEVICE(OBJ,STRUCT) 
%    parses the input structure, STRUCT, into property names (PROP1 and PROP2)
%    and indices (INDEX1 and INDEX2).
%
%    For example, ai(1).Channel(2).ChannelName would parse into
%    INDEX1 = 1, PROP1 = 'Channel', INDEX2 = 2, PROP2 = ChannelName.
%
%    PRIVATEPARSEDEVICE is a helper function for @daqdevice\subsref and
%    @daqdevice\subsasgn.
%

%    MP 6-03-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.9.2.9 $  $Date: 2008/08/08 12:50:55 $


% Initialize variables
StructL = length(Struct);
prop1 = '';
prop2 = '';
index1 = {};
index2 = {};

% Define possible error messages
error1ID = 'daq:privateparsedevice:inconsistParens';
error1 = 'Inconsistently placed ''()'' in subscript expression.';
error2ID = 'daq:privateparsedevice:cellRefFromNonCell';
error2 = 'Cell contents reference from a non-cell array object.';
error3ID = 'daq:privateparsedevice:inconsistDot';
error3 = 'Inconsistently placed ''.'' in subscript expression.';
error4ID = 'daq:privateparsedevice:cantAccessEventLog';
error4 = 'To access the array of event structures stored in the object''s EventLog\nyou must assign it to another variable.\nExample: events = obj.EventLog;';
error5ID = 'daq:privateparsedevice:unkSubsRefType';
error5 = 'Unknown type: %s.';

% Parse the input structure, Struct, into the index1, prop1, index2  
% and prop2 variables.  Syntax: obj(index1).prop1(index2).prop2.

% The first Struct can either be:
% obj(1); 
% obj.SampleRate;
switch Struct(1).type
case '.'
   prop1 = Struct(1).subs;
case '()'
   index1 = Struct(1).subs;
   if length(index1) > 1
      % Ex. obj(1,2) 
      index1 = localCheckIndex(Obj, index1);
   end
case '{}'
   error(error2ID,error2);
otherwise
   error(error5ID,error5,Struct(1).type);
end

if StructL > 1
   % Ex. obj.Channel.ChannelName;
   % Ex. obj(1).Channel;
   % Ex. obj.Channel(1);
   switch Struct(2).type
   case '.'
      if isempty(index1)
         % In the case of the EventLog there is no way to access the array
         % of structures directly so an error message is emitted.
         if strcmp(prop1, 'EventLog')
            error(error4ID,error4);
         end
         % Ex. obj.Channel.ChannelName;
         prop2 = Struct(2).subs;
      else
         % Ex. obj(1).Channel;
         prop1 = Struct(2).subs;
      end
   case '()'
      % Ex. obj.Channel(1);
      index2 = Struct(2).subs;
   case '{}'
      error(error2ID,error2);
   otherwise
      error(error5ID,error5,Struct(2).type);
   end  
   
   if StructL > 2
      % Ex. ai.Channel(1).ChannelName
      % Ex. ai(1).Channel(1)
      switch Struct(3).type
      case '.'
         if isempty(prop2)
            prop2 = Struct(3).subs; 
         else
            error(error3ID,error3);
         end
      case '()'
         index2 = Struct(3).subs;
      case '{}'
         error(error2ID,error2);
      otherwise
         error(error5ID,error5,Struct(3).type);
      end
      
      if StructL > 3
         % Ex. ai(1).Channel(1).ChannelName
         switch Struct(4).type
         case '.'
            prop2 = Struct(4).subs; 
         case '()'
            error(error1ID,error1);
         case '{}'
            error(error2ID,error2);
         otherwise
            error(error5ID,error5,Struct(4).type);
         end
         if StructL > 4
            error('daq:privateparsedevice:inconsistInSub',...
                'Inconsistently placed ''%s'' in subscript expression.',...
                Struct(5).type);
         end
      end
   end
end

% ********************************************************************
% Check the multiple indices.
function index = localCheckIndex(obj, index)

% Initialize variables.
[m,n] = size(obj);
error1ID = 'daq:privateparsechild:badsubscript'; 
error1 = 'Index exceeds matrix dimensions.'; 
error2ID = 'daq:privateparsedevice:indexInvalid';
error2 = 'Index passed was invalid';

% For the indices above 2, it is only valid if the index is 1 or ':'.
% If it is empty, an empty matrix in a cell should be returned.
for i = 3:length(index)
   if ~isempty(index{i}) && ~(strcmp(index{i}, ':') || all(index{i} == 1)) 
      error(error1ID,error1);
   end
   if isempty(index{i})
       index = {[]};
       return
   end
end

% If either of the first two indices are empty then return empty matrix in a cell.
if isempty(index{1}) || isempty(index{2})
    index = {[]};
    return
end

% Compare the first index to the number of rows.
if max(index{1}) > m || min(index{1}) < 1 
   if ~strcmp(index{1}, ':') 
      error(error1ID,error1);
   end
end

% Compare the second index to the number of columns.
if max(index{2}) > n || min(index{2}) < 1 
   if ~strcmp(index{2}, ':')
      error(error1ID,error1);
   end
end

% If obj is a row vector, replace index{1} with index{2} so only one 
% element of index is used and it doesn't have to be checked.
% Ex. obj(1,5) becomes obj(5,5) but only the first index is used.
if m == 1
   index{1} = index{2};
end
