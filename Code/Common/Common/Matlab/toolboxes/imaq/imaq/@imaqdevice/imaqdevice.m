function obj = imaqdevice(arg)
%IMAQDEVICE Construct imaqdevice object.
%
%    IMAQDEVICE is the base class from which videoinput
%    objects are derived from.  It is used to allow these 
%    objects to inherit common methods.
%
%    This function should not be used directly by users.
% 
%    See also VIDEOINPUT.
%

%    CP 9-01-01
%    Copyright 2001-2010 The MathWorks, Inc.

% Determine if function was called by the toolbox.
if ((nargin~=1) || ~ischar(arg) || ~strcmp('imaqdevice', arg))
    error(message('imaq:imaqdevice:invalidSyntax'));
end

% Create an empty dummy object
obj.store={};
obj = class(obj,'imaqdevice');
