function out = length(obj)
%LENGTH Length of data acquisition object.
%
%    LENGTH(OBJ) returns the length of data acquisition object, OBJ.  
%    It is equivalent to MAX(SIZE(OBJ)).  OBJ can be a device object 
%    or a channel/line.
%    
%    See also DAQHELP, DAQCHILD/SIZE.
%

%    MP 4-15-98
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.9.2.5 $  $Date: 2004/12/01 19:46:49 $

% The handle property of the object indicates the number of 
% objects that are concatenated together.
if any(strcmp(class(obj), {'aochannel', 'aichannel', 'dioline'}))
   h = struct(obj);
   out = builtin('length', h.uddobject);
else
   out = 1;
end