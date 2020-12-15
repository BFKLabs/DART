function varargout = imaqslgate(varargin)
%IMAQSLGATE Gateway routine to call Image Acquisition Toolbox SL private functions.
%
%    [OUT1, OUT2,...] = IMAQSLGATE(FCN, VAR1, VAR2,...) calls FCN in 
%    the Image Acquisition Toolbox Simulink private directory with input arguments
%    VAR1, VAR2,... and returns the output, OUT1, OUT2,....
%

%    SS 09-19-06
%    Copyright 1998-2011 The MathWorks, Inc.

if nargin == 0
   error(message('imaq:imaqblks:argcheck'));
end

nout = nargout;
if nout==0,
   feval(varargin{:});
else
   [varargout{1:nout}] = feval(varargin{:});
end
