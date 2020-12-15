function iseq=eq(arg1, arg2)
%EQ Overload of == for data acquisition objects.
%

%    MP 12-22-98   
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.11.2.6 $  $Date: 2007/09/18 02:04:03 $

% Turn off warning backtraces.
s = warning('off', 'backtrace');

% Error if both the objects have a length greater than 1 and have
% different sizes.
if prod(size(arg1))~=1 && prod(size(arg2))~=1
	if size(arg1,1)~=size(arg2,1) || size(arg1,2)~=size(arg2,2)
        warning(s);
		error('daq:eq:size', 'Matrix dimensions must agree.')
	end
end

% Warn appropriately if one of the input arguments is empty.
if isempty(arg1)
    iseq = logical([]);
    warning(s);
	return;
elseif isempty(arg2)
    iseq = logical([]);
    warning(s);
	return;
end
% Restore warning backtrace state.
warning(s);

% Determine if both objects are daqdevice objects.
if isa(arg1, 'daqdevice') && isa(arg2, 'daqdevice')

   % Return FALSE if one of the objects has an invalid handle.
   if ~any(isvalid(arg1)) || ~any(isvalid(arg2))
    	iseq = logical(0);
		return;
   end
      
   % If the objects are not of length 1, loop through each object and 
   % determine if they are equal.
   if prod(size(arg1))~=1 && prod(size(arg2))~=1
      % Initialize variables.      
      iseq = logical(zeros(size(arg1)));
      
      % Get the handles to the input arguments.
      uddobj1 = daqgetfield(arg1, 'uddobject');
      uddobj2 = daqgetfield(arg2, 'uddobject');
      for i = 1:length(arg1)
         % The object's are equal if the objects have the same handle and 
         iseq(i) = (uddobj1(i) == uddobj2(i));
      end
   elseif prod(size(arg1))==1,
      % If arg1 is of length one, then determine if each element of arg2
      % is equal to arg1.
      
      % Initialize variables.
      iseq = logical(zeros(size(arg2)));
      
      % Obtain arg1's handle.
      uddobj1 = daqgetfield(arg1, 'uddobject');   
            
      % Get all the handles for arg2.
      uddobjs = daqgetfield(arg2, 'uddobject');
      
      % Loop through each element of arg2 and compare to arg1.
      for i = 1:length(arg2)
                 
         % The object's are equal if they have the same handle.
         iseq(i) = ( uddobj1==uddobjs(i) );
      end
   elseif prod(size(arg2))==1
      % If arg2 is of length one, then determine if each element of arg1
      % is equal to arg2.
      
      % Initialize variables.
      iseq = logical(zeros(size(arg1)));
      
      % Obtain arg2's handle and CreationTime.
      uddobj2 = daqgetfield(arg2, 'uddobject');
            
      % Get all the handles for arg1.
      uddobjs = daqgetfield(arg1, 'uddobject');
      
      % Loop through each element of arg1 and compare to arg2.
      for i = 1:length(arg1)
                  
         % The object's are equal if they have the same handle.
         iseq(i) = ( uddobj2 == uddobjs(i) );
      end
   end
elseif ~isempty(arg1) && ~isempty(arg2)
   % One of the object's are not a daqchild and therefore unequal.
   % Error if both the objects have a length greater than 1 and have
   % different sizes.
   if prod(size(arg1))~=1 && prod(size(arg2))~=1
      if size(arg1,1)~=size(arg2,1) || size(arg1,2)~=size(arg2,2)
         error('daq:eq:size', 'Matrix dimensions must agree.')
      end
   end
   % Return a logical zero. 
   iseq = logical(0);
end

