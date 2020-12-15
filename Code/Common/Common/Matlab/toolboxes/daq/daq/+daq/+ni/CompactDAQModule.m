classdef (Hidden) CompactDAQModule < daq.ni.DeviceInfo
    %CompactDAQModule Device info for National Instruments CompactDAQ modules.
    %
    %    This class represents CompactDAQ modules by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    % Specializations of the daq.DeviceInfo class should call addSubsystem
    % repeatedly to add a SubsystemInfo record to their device. usage:
    % addSubsystem(SUBSYSTEM) adds an adaptor specific SubsystemInfo record
    % SUBSYSTEM to the device.
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        ChassisName
        ChassisModel
        SlotNumber
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = CompactDAQModule(vendor,device)
            % Call the superclass constructor
            obj@daq.ni.DeviceInfo(vendor, device);
            
            % Get the chassis name
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevCompactDAQChassisDevName(device,' ',uint32(0));
            [status,compactDAQChassisDevName] = daq.ni.NIDAQmx.DAQmxGetDevCompactDAQChassisDevName(device,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.ChassisName = compactDAQChassisDevName;
            % G698912 Get the chassis model
            [bufferSize,~] =  daq.ni.NIDAQmx.DAQmxGetDevProductType(compactDAQChassisDevName,' ',uint32(0));
            [status,devProductType] = daq.ni.NIDAQmx.DAQmxGetDevProductType(compactDAQChassisDevName,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.ChassisModel = devProductType;
            % Get the Slot number of this module
            [status,compactDAQSlotNum] = daq.ni.NIDAQmx.DAQmxGetDevCompactDAQSlotNum(device,uint32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.SlotNumber = compactDAQSlotNum;
            
            % For a compactDAQ module, the terminal property will contain
            % the terminals for the chassis and modules. This is done to
            % support module PFIs for synchronization purposes. For more
            % information see g835021.
            obj.Terminals = [ daq.ni.DeviceInfo.getTerminalsFromDevice(compactDAQChassisDevName);...
                               daq.ni.DeviceInfo.getTerminalsFromDevice(device)];
                        
        end
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function result = getSpecializedFamily(obj) %#ok<MANU>
            result = 'CompactDAQ';
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function suffixText = getSingleDispSuffixHook(obj)
            %getSingleDispSuffixImpl Subclasses override to customize disp
            %suffixText = getSingleDispSuffixImpl() Optional override by
            %DeviceInfo subclasses to allow them to append custom
            %information to the disp of a single DeviceInfo object.
            
            suffixText = sprintf('This module is in slot %s of the ''%s'' chassis with the name ''%s''.',...
                num2str(obj.SlotNumber),obj.ChassisModel,obj.ChassisName);
        end
    end
    
end
