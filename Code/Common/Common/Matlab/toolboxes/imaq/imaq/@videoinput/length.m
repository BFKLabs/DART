function out = length(obj)
%LENGTH Length of image acquisition object array.
%
%    LENGTH(OBJ) returns the length of video input object 
%    array, OBJ. It is equivalent to MAX(SIZE(OBJ)).  
%    
%    See also IMAQHELP.
%

%    CP 9-01-01
%    Copyright 2001-2009 The MathWorks, Inc.

% The UDD object property of the object indicates the number of 
% objects that are concatenated together.
try
   out = builtin('length', obj.uddobject);
catch %#ok<CTCH>
   out = 1;
end




