function warnInfo = privateCheckAdaptorMismatch(adaptor)
% PRIVATECHECKADAPTORMISMATCH(ADAPTORDLLNAME) warns if adaptor not under MATLAB root
%
%   PRIVATECHECKADAPTORMISMATCH(ADAPTOR) returns a warning message
%   if the path where ADAPTOR resides is not located under the
%   MATLAB root. An empty string is returned if it is under the root or if
%   it appears to be a third party adaptor which by definition will not be
%   under the MATLAB root directory.

%   PRIVATECHECKADAPTORMISMATCH is a helper function for ANALOGINPUT,
%   ANALOGOUTPUT, DIGITALIO and DAQSUPPORT.
%
%   Copyright 2007-2010 The MathWorks, Inc.

warnInfo = [];

% If we are deployed do not run the check.
% If not deployed find the expected root for the adaptor.
if isdeployed
    return;
else
    root = matlabroot;
end

try
    % Disable the session-based interface warning for a moment
    sWarnings = warning('off','daq:daqhwinfo:v3');
    AdaptorDllName = daqhwinfo(adaptor, 'AdaptorDllName');
    warning(sWarnings);
catch %#ok<CTCH>
    warning(sWarnings);
    % If daqhwinfo fails return without trying to set the warning.
    return;
end

% Third party adaptors will not be in under the Data Acquisition Toolbox directory.
if isempty(strfind(lower(AdaptorDllName),'toolbox\daq\daq\private'))
    return
end

if isempty(strfind(lower(AdaptorDllName), lower(root)))
    warnInfo = sprintf('%s\n%s%s\n%s%s\n%s\n%s%s%s\n%s', ...
        'The device adaptor is not in the expected location.', ...
        'Expected: ', root, ...
        'Actual:   ', AdaptorDllName, ...
        'An adaptor from the wrong release may be in use. To correct this problem execute:', ...
        '    daqregister(''', adaptor, ''',''unload'')', ...
        'Then exit and restart MATLAB.');
end

