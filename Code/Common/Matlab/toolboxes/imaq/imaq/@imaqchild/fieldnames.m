function out = fieldnames(obj, flag) %#ok<INUSD>
%FIELDNAMES Get image acquisition object property names.
%
%    NAMES = FIELDNAMES(OBJ) returns a cell array of strings containing 
%    the names of the properties associated with image acquisition object, OBJ.
%    OBJ can be an array of image acquisition objects of the same type.
%
%    See also VIDEOINPUT, IMAQDEVICE/GET.

%    CP 8-24-02
%    Copyright 2001-2010 The MathWorks, Inc.

if ~isa(obj, 'imaqchild')
    error(message('imaq:fieldnames:invalidType'));
end

% Error if invalid.
if ~all(isvalid(obj)),
    error(message('imaq:fieldnames:invalidOBJ'));
end

try
    out = fieldnames(get(obj));
catch %#ok<CTCH>
    error(message('imaq:fieldnames:mixedArray'));
end
