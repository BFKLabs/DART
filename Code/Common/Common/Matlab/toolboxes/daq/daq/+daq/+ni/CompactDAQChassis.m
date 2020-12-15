classdef (Hidden) CompactDAQChassis < daq.ni.DeviceInfo
    %CompactDAQChassis Device info for National Instruments CompactDAQ chassis.
    %
    %    This class represents CompactDAQ chassis by
    %    National Instruments.  This is used by the daq.ni.Sync class to
    %    represent these devices.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2011-2012 The MathWorks, Inc.
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = CompactDAQChassis(vendor,device)
            % Call the superclass constructor
            obj@daq.ni.DeviceInfo(vendor, device);
        end
    end
    
    methods( Hidden , Access = public)
        
        % Find all modules in the chassis
        function result = findModules(obj)     
        
            % g873066,873097,885613: Fixed LXE incompatibility warnings
            HardwareInfo = daq.HardwareInfo.getInstance();        
            allDevices = HardwareInfo.Devices;

            result = allDevices(arrayfun(@(x) isa(x,'daq.ni.CompactDAQModule') && ...
                strcmp(x.ChassisName,obj.ID) ,...
                allDevices));
        end
    end
end
