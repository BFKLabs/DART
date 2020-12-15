function obj = isetfield(obj, field, value)
%ISETFIELD Set image acquisition object internal fields.
%
%    OBJ = ISETFIELD(OBJ, FIELD, VAL) sets the value of OBJ's FIELD 
%    to VAL.
%
%    This function is a helper function for the concatenation and
%    manipulation of image acquisition object arrays. This function should
%    not be used directly by users.
%
%    See also VIDEOINPUT.

%    CP 9-3-2002
%    Copyright 2001-2009 The MathWorks, Inc.

% Assign the specified field information.
try
    obj.(field) = value;
catch %#ok<CTCH>
    error(message('imaq:isetfield:invalidField', field));
end
