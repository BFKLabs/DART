function isneq=ne(arg1, arg2)
%NE Overload of ~= for data acquisition objects.
%

%    DTL 9-1-2004    
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.10.2.5 $  $Date: 2004/12/01 19:46:50 $

isneq = ~eq(arg1,arg2);
