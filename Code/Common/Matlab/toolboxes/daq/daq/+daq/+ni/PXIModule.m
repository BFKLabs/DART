classdef (Hidden) PXIModule < daq.ni.DeviceInfo
    %PXIModule Device info for National Instruments PXI modules.
    %
    %    This class represents PXI modules by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2011-2012 The MathWorks, Inc.
    
    % Specializations of the daq.DeviceInfo class should call addSubsystem
    % repeatedly to add a SubsystemInfo record to their device. usage:
    % addSubsystem(SUBSYSTEM) adds an adaptor specific SubsystemInfo record
    % SUBSYSTEM to the device.
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        
        %ChassisNumber A scalar indicating the PXI chassis number of the
        % device, as identified in MAX
        ChassisNumber
        
        %SlotNumber A scalar indicating the PXI slot number of the device
        SlotNumber
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = PXIModule(vendor,device)
            % Call the superclass constructor
            obj@daq.ni.DeviceInfo(vendor, device);
            
            % Get the chassis number
            [status, PXIChassisNumber] = daq.ni.NIDAQmx.DAQmxGetDevPXIChassisNum(device,uint32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.ChassisNumber = PXIChassisNumber;
            
            % Get the Slot number of this module
            [status,PXISlotNum] = daq.ni.NIDAQmx.DAQmxGetDevPXISlotNum(device,uint32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.SlotNumber = PXISlotNum;
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function suffixText = getSingleDispSuffixHook(obj)
            %getSingleDispSuffixImpl Subclasses override to customize disp
            %suffixText = getSingleDispSuffixImpl() Optional override by
            %DeviceInfo subclasses to allow them to append custom
            %information to the disp of a single DeviceInfo object.
            
            suffixText = sprintf('This module is in slot %s of the PXI Chassis %s.',...
                num2str(obj.SlotNumber),num2str(obj.ChassisNumber));
        end
    end
    
end
