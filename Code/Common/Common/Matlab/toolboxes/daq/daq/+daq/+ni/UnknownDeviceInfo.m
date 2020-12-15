classdef (Hidden) UnknownDeviceInfo < daq.DeviceInfo
    %UnknownDeviceInfo Device info for unrecognized National Instruments devices.
    %
    %    This class represents unrecognized devices by National Instruments.
    %
    %    This undocumented class may be removed in a future release.
   
    % Copyright 2010-2012 The MathWorks, Inc.

    % Specializations of the daq.UnknownDeviceInfo class should call addSubsystem
    % repeatedly to add a SubsystemInfo record to their device. usage:
    % addSubsystem(SUBSYSTEM) adds an adaptor specific SubsystemInfo record
    % SUBSYSTEM to the device.

    %% -- Public methods, properties, and events --

    % Read only properties
    properties (SetAccess = private)
        IsSimulated
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = UnknownDeviceInfo(vendor,device)
            % ------------ Stuff that probably belongs in a superclass -----------------
            % Get the device type/model
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevProductType(device,' ',uint32(0));
            [status,devProductType] = daq.ni.NIDAQmx.DAQmxGetDevProductType(device,blanks(bufferSize),uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % Is the device simulated?
            [status,isSimulated] = daq.ni.NIDAQmx.DAQmxGetDevIsSimulated(device,uint32(0));
            daq.ni.utility.throwOrWarnOnStatus(status);
            isSimulated = (isSimulated ~= 0);
            
            % Call the superclass constructor
            obj@daq.DeviceInfo(vendor, device, devProductType);

            obj.IsSimulated = isSimulated;

            % Only recognize if it's got a subsystem we understand
            obj.RecognizedDevice = false;
        end
    end
end
