classdef (Hidden) VendorInfo < daq.sdk.VendorInfo
    %VendorInfo MCC driver
    %
    %    This class represents a MCCAdaptor based driver.
    
    % Copyright 2016 The MathWorks, Inc.
    
    %% Lifetime
    methods
        function obj = VendorInfo()
            
            adaptorName = 'MCCAdaptor';
            packageName = 'mcc';
            minSupportedDriverVersion = daq.sdk.VersionInfo(1, 0, 0);
            minSupportedFirmwareVersion = daq.sdk.VersionInfo(1, 0, 0);
            
            obj@daq.sdk.VendorInfo(adaptorName, ...
                packageName, ...
                minSupportedDriverVersion, ...
                minSupportedFirmwareVersion);
        end
    end
end
