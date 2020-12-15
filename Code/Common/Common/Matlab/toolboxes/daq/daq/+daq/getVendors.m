function [vendorInfo] = getVendors()
%DAQ.GETVENDORS Show data acquisition vendors available
%
%   VENDORS = DAQ.GETVENDORS() returns VENDORS, an mx1 array of
%   daq.VendorInfo objects that describe the vendors that are available on
%   this system.
%
% Example:
% vendors = daq.getVendors()
%
% See also DAQ.GETDEVICES, DAQ.RESET

% Copyright 2009-2011 The MathWorks, Inc.

    try
        hw = daq.HardwareInfo.getInstance();
        vendorInfo = hw.KnownVendors;
        % Return only the vendors who are not Hidden.  Hidden Vendors allow for
        % long term maintenance and backward compatibility.
        vendorInfo = vendorInfo(~[vendorInfo.IsVendorHidden]);
    catch e
        % Rethrow any errors as caller, removing the long stack of
        % errors -- capture the full exception in the cause field
        % if FullDebug option is set.
        if daq.internal.getOptions().FullDebug
            rethrow(e)
        end
        e.throwAsCaller()
    end
end

