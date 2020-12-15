function privateDoPreviewFromJava(uddobj)
% PRIVATEDOPREVIEWFROMJAVA Helper function to allow previewing.
%
%   This function allows java code to invoke the VIDEOINPUT preview
%   window.
%
%   This is a helper function meant to be called by the tools outside of
%   the toolbox.

%    DT 3/2005
%    Copyright 2005 The MathWorks, Inc.

obj = videoinput(uddobj);
preview(obj);