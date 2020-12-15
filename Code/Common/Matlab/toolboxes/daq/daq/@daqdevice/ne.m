function isneq=ne(arg1, arg2)
%NE Overload of ~= for data acquisition objects.
%

%    MP 12-22-98   
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.11.2.5 $  $Date: 2004/12/01 19:47:09 $

isneq = ~eq(arg1,arg2);
