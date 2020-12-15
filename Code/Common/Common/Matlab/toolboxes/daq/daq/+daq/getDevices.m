function [deviceInfo] = getDevices()
%DAQ.GETDEVICES Show data acquisition devices available
%
%   DEVICES = DAQ.GETDEVICES returns DEVICES, an mx1 array of
%   daq.DeviceInfo objects that describe the devices that are available on
%   this system.
%
% Example:
% devices = daq.getDevices()
%
% See also DAQ.CREATESESSION, DAQ.GETVENDORS, DAQ.RESET

% Copyright 2009-2013 The MathWorks, Inc.
    
    ws = warning('off', 'MATLAB:class:cannotUpdateClass:Missing');
    oc = onCleanup(@()warning(ws));
    try
        hw = daq.HardwareInfo.getInstance();
        deviceInfo = hw.Devices;
    catch e
        % Rethrow any errors as caller, removing the long stack of
        % errors -- capture the full exception in the cause field
        % if FullDebug option is set.
        options = daq.internal.getOptions();
        if options.FullDebug
            rethrow(e)
        end
        e.throwAsCaller()
    end
end
