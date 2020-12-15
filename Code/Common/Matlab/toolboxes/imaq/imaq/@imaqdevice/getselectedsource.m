function src = getselectedsource(obj)
%GETSELECTEDSOURCE Return the current selected video source object.
% 
%    SRC = GETSELECTEDSOURCE(OBJ) searches OBJ's Source property 
%    and returns a video source object, SRC, that has a 
%    Selected property value of 'on'.
%
%    OBJ must be a 1x1 video input object.
%
%    See also VIDEOINPUT, IMAQHELP, IMAQDEVICE/GET.
%

%    CP 9-05-02
%    Copyright 2001-2010 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'imaqdevice')
    error(message('imaq:getselectedsource:invalidType'));
elseif (length(obj) > 1)
    error(message('imaq:getselectedsource:OBJ1x1'));
elseif ~isvalid(obj)
    error(message('imaq:getselectedsource:invalidOBJ'));
end

% Locate and return the selected source object.
sources = get(obj, 'Source');
selectedVals = get(sources, 'Selected');
src = sources(strcmp('on', selectedVals));
