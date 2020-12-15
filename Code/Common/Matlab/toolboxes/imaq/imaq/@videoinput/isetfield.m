function obj = isetfield(obj, field, value)
%ISETFIELD Set video input object internal fields.
%
%    OBJ = ISETFIELD(OBJ, FIELD, VAL) sets the value of OBJ's FIELD 
%    to VAL.
%
%    This function is a helper function manipulation of image acquisition 
%    object arrays. This function should not be used directly by users.
%

%    CP 9-01-01
%    Copyright 2001-2010 The MathWorks, Inc.

% Assign the specified field information.
try
    obj.(field) = value;
catch %#ok<CTCH>
    error(message('imaq:isetfield:invalidField', field));
end