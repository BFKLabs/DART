function obj = daqsetfield(obj, field, value)
%DAQSETFIELD Set and get data acquisition internal fields.
%
%    OBJ = DAQSETFIELD(OBJ, FIELD, VAL) sets the value of OBJ's FIELD to VAL.
%
%    This function is a helper function for the concatenation and manipulation
%    of device object arrays.
%

%    MP 12-22-98   
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.1.6.1 $  $Date: 2004/12/01 19:46:35 $

% Assign the specified field information.
switch field
case 'uddobject'
   obj.uddobject = value;
case 'version'
   obj.version = value;
otherwise
   error('daq:daqsetfield:invalidfield', 'Unable to set the field: %s', field);
end
