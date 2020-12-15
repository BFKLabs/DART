function out = privateGetField(obj, field)
%PRIVATEGETFIELD Get image acquisition object internal fields.
%
%    VAL = PRIVATEGETFIELD(OBJ, FIELD) returns the value of object's, OBJ,
%    FIELD to VAL.
%
%    This function is a helper function used to access image acquisition 
%    object fields. This function should not be used directly by users.
%

%    CP 9-01-01
%    Copyright 2001-2011 The MathWorks, Inc. 

% Convert object to structure so we can access its fields.
objStruct = struct(obj);

% Return the specified field information.
try
    out = objStruct.(field);
catch %#ok<CTCH>
    error(message('imaq:privateGetField:invalidField', field));
end
