function throwOrWarnOnStatus( niStatusCode )
%THROWORWARNONSTATUS Throw an error or fire a warning based on NI status
%
%    This undocumented function may be removed in a future release.

% Copyright 2010-2012 The MathWorks, Inc.

% g639771: Check the status against daq.ni.NIDAQmx.DAQmxSuccess, which is
% zero. For performance improvements do not call
% daq.ni.NIDAQmx.DAQmxSuccess and instead use the constant 0. This function
% is very heavily used in DAQ toolbox code base and this optimizations
% shows improvement in daq.getDevices performance.
if ~ niStatusCode
    return
end

if niStatusCode < 0
    % Capture the extended error string
    % First, find out how big it is
    [numberOfBytes,~] = daq.ni.NIDAQmx.DAQmxGetExtendedErrorInfo(' ', uint32(0));
    % Now, get the message
    [~,extMessage] = daq.ni.NIDAQmx.DAQmxGetExtendedErrorInfo(blanks(numberOfBytes), uint32(numberOfBytes));
    
    % Status code is less than 0 -- It is a NI-DAQmx error, throw an error
    errorToThrow = MException(sprintf('nidaq:ni:err%06d',-1 * niStatusCode),...
        'NI Error %06d:\n%s', niStatusCode,extMessage);
    throwAsCaller(errorToThrow)
else
    if niStatusCode ~= 200010 % G683870 - Suppress some NI-DAQmx warnings
        % It is a NI-DAQmx warning, warn
        [numberOfBytes,~] = daq.ni.NIDAQmx.DAQmxGetErrorString(niStatusCode,' ', uint32(0));
        [~,extMessage] = daq.ni.NIDAQmx.DAQmxGetErrorString(niStatusCode,blanks(numberOfBytes), uint32(numberOfBytes));
        sWarningBacktrace = warning('off','backtrace');
        warning(message('nidaq:ni:NIDAQmxStatusCode', niStatusCode, extMessage));
        warning(sWarningBacktrace);
    end
end

end

