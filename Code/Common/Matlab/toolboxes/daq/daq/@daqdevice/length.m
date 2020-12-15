function out = length(obj)
%LENGTH Length of data acquisition object.
%
%    LENGTH(OBJ) returns the length of data acquisition object, OBJ.  
%    It is equivalent to MAX(SIZE(OBJ)).  OBJ can be a device object 
%    array or a channel/line.
%    
%    See also DAQHELP, DAQDEVICE/SIZE.
%

%    MP 4-15-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.5.2.6 $  $Date: 2008/06/16 16:35:15 $

% The handle property of the object indicates the number of 
% objects that are concatenated together.
try
   h = struct(obj);
   out = builtin('length', h.uddobject);
catch e %#ok<NASGU>
   out = 1;
end

