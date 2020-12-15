function iseq=eq(arg1, arg2)
%EQ Overload of == for data acquisition objects.
%

%    DTL 9-1-2004
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.10.2.7 $  $Date: 2013/04/12 03:15:31 $

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

% Determine if both objects are daqchild object.
if isa(arg1, 'daqchild') && isa(arg2, 'daqchild')

   % Return FALSE if one of the objects has an invalid handle.
   if ~any(isvalid(arg1)) || ~any(isvalid(arg2))
    	iseq = logical(0);
		return;
   end
   
   % If the two objects are not of the same class, they are not equal - 
   % return 0.
   if ~strcmp(class(arg1),class(arg2))
      iseq = logical(0);
      return;
   end
   
   % If the objects are not of length 1, loop through each object and 
   % determine if they are equal.
   if prod(size(arg1))~=1 && prod(size(arg2))~=1
      for i=1:length(arg1)
         % Get access to the daqchild object's uddobject.
         arg1i=hindexobj(arg1,i);
         arg2i=hindexobj(arg2,i);
         h1=struct(arg1i);
         h2=struct(arg2i);
         
         % Get access to the daqchild object's parent.
         P1=get(arg1i,'parent');
         P2=get(arg2i,'parent');
         
         % Get access to the daqchild object's parent' uddobject.
         p1=struct(P1);
         p2=struct(P2);
         
         % The object's are equal if the objects have the same handle and
         % their parents have the same handle.
         isEQ = ( p1.uddobject==p2.uddobject & h1.uddobject==h2.uddobject );
         iseq(i)=isEQ;
      end
   elseif prod(size(arg1))==1,
      % If arg1 is of length one, then determine if each element of arg2
      % is equal to arg1.
      
      % Obtain arg1's handle.
      h1=struct(arg1);
      uddobj=h1.uddobject;   
      
      % Obtain arg1's parent's handle.
      P1=get(arg1,'parent');
      p1=struct(P1);
      puddobj=p1.uddobject;
            
      % Loop through each element of arg2 and compare to arg1.
      for i=1:length(arg2)
         % Get access to arg2's handle.
         h2=struct(arg2(i));
         
         % Get access to arg2's parent's handle.
         P2=get(arg2(i),'parent');
         p2=struct(P2);
         
         % The object's are equal if they have the same handle,
         % and their parent's have the same handle.
         isEQ = ( puddobj==p2.uddobject & uddobj==h2.uddobject );
         iseq(i)=isEQ;
      end
   elseif prod(size(arg2))==1
      % If arg2 is of length one, then determine if each element of arg1
      % is equal to arg2.
      
      % Obtain arg2's handle.
      h2=struct(arg2);
      uddobj=h2.uddobject;
      
      % Obtain arg2's parent's handle.
      P2=get(arg2,'parent');
      p2=struct(P2);
      puddobj=p2.uddobject;
            
      % Loop through each element of arg1 and compare to arg2.
      for i=1:length(arg1)
         % Get access to arg1's handle.
         arg1i=hindexobj(arg1,i);

         h1=struct(arg1i);
         
         % Get access to arg1's parent's handle.
         P1=get(arg1i,'parent');
         p1=struct(P1);
         
         % The object's are equal if they have the same handle,
         % and their parent's have the same handle.
         isEQ = ( p1.uddobject==puddobj & h1.uddobject==uddobj );
         iseq(i)=isEQ;
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

% Invert the output - since channels are columns.
iseq = iseq';

