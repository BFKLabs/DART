function obj = imaqchild(arg)
%IMAQCHILD Construct imaqchild object.
%
%    IMAQCHILD is the base class from which image acquisition
%    video source objects are derived from. It is used to allow these 
%    objects to inherit common methods.
%
%    This function is not intended to be used directly.
%
%    See also VIDEOINPUT, VIDEOSOURCE.
%

%    CP 1-25-02
%    Copyright 2001-2010 The MathWorks, Inc.

% Determine if function was called by the toolbox.
if ((nargin~=1) || ~strcmp('imaqchild', arg))
    error(message('imaq:imaqchild:invalidSyntax'));
end

% Create an empty dummy object
obj.store = {};
obj = class(obj,'imaqchild');
