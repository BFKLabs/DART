function out = daqgetfield(obj, field)
%DAQGETFIELD Set and get data acquisition internal fields.
%
%    VAL = DAQGETFIELD(OBJ, FIELD) returns the value of object's, OBJ,
%    FIELD to VAL.
%
%    This function is a helper function for the concatenation and 
%    manipulation of device object arrays.
%

%    MP 12-22-98   
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.1.6.1 $  $Date: 2004/12/01 19:46:34 $

% Return the specified field information.
switch field
case 'uddobject'
   out = obj.uddobject;
case 'version'
   out = obj.version;
case 'daqchild'
   out = obj.daqchild;
otherwise
   error('daq:daqgetfield:invalidfield', 'Invalid field: %s', field);
end
