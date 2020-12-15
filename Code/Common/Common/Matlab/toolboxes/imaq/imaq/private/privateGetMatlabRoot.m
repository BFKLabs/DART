function mlRoot = privateGetMatlabRoot
% PRIVATEGETMATLABROOT Determine MATLABROOT for the toolbox
%
%   PRIVATEGETMATLABROOT returns the MATLABROOT with respect to the toolbox.
%   It takes into account the fact that the toolbox could be deployed via
%   the MATLAB compiler.  In that case the directory where the toolbox
%   lives is not relative to MATLABROOT but CTFROOT instead.
%
%   PRIVATEGETMATLABROOT is an internal toolbox function and is not intended
%   for public use.
%
%   See also MATLABROOT, CTFROOT.

% DT 11/2005
% Copyright 2005-2009 The MathWorks, Inc.

if exist('ctfroot') %#ok<EXIST>
    mlRoot = ctfroot;
else
    mlRoot = matlabroot;
end
