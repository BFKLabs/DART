classdef (Hidden) USB9219 < daq.ni.DeviceInfo
    %USB-9219 Device info for National Instruments CompactDAQ modules.
    %
    %    This class represents USB-9219 by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
   
    % Copyright 2011 The MathWorks, Inc.

    % Specializations of the daq.DeviceInfo class should call addSubsystem
    % repeatedly to add a SubsystemInfo record to their device. usage:
    % addSubsystem(SUBSYSTEM) adds an adaptor specific SubsystemInfo record
    % SUBSYSTEM to the device.

    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = USB9219(vendor,device)
            % Call the superclass constructor
            obj@daq.ni.DeviceInfo(vendor, device);
        end
        
        function rateLimit = getRateLimitFromDataSheet(obj,...
                               measurmentType) %#ok<MANU>
            % These rates are hard-coded from data-sheet because NI does not
            % provide a way to query rates based on measurement type for 
            % this device.
            switch measurmentType
                case 'Thermocouple'
                    rateLimit = [ 0 50 ];
                    return;
                otherwise
                    rateLimit = [ 0 100 ];
            end
        end
    end
end
