classdef (Hidden) AnalogInputVoltageChannel < daq.ni.AnalogInputVoltageChannel & daq.ni.DSACommonChannelAttrib
    %AnalogInputVoltageChannel All settings & operations for anNI PXI DSA
    %analog input voltage channel. The DSACommonChannelAttrib provides the
    %common functionality for all DSA devices.
    
    % Copyright 2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputVoltageChannel(session,deviceInfo,channelID)
            %AnalogInputVoltageChannel All settings & operations for a CompactDAQ analog input voltage channel added to a session.
            %    AnalogInputVoltageChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.AnalogInputVoltageChannel(session,deviceInfo,channelID);
            obj@daq.ni.DSACommonChannelAttrib();
        end
    end
    
    % Destructor
    methods(Access=protected)
        % Needed just to keep the access settings for all destructors
        % consistent (it'd be "public" if it were deleted.
        function delete(~)
        end
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
    end
    
    % Superclass methods this class implements
    methods (Hidden, Sealed, Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the group name for this channel.
            %
            % Override the default group name assignment.
            % The group name is based on the AutoSyncDSA property setting.
            % When AutoSyncDSA is true, all the PXI DSA boards in a session
            % need to be synchronized and are therefore put in a single NI
            % task. We do this by assigning it a common groupName which is
            % dependent on the PXI Chassis Number.
            if obj.Session.AutoSyncDSA
                groupName = ['ai/PXI' num2str(obj.Device.ChassisNumber)];
            else
                groupName = ['ai/' obj.Device.ID];
            end
        end
        
        function [session] = getSession(obj)
            session = obj.Session;
        end 
        
    end
    
    % Override the base class createChannel
    methods (Access = protected)
        function createChannel(obj,taskHandle,niTerminalConfig,range)
            [status] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan (...
                taskHandle,...                                  % The task handle
                obj.PhysicalChannel,...                         % physicalChannel
                char(0),...                                     % nameToAssignToChannel
                niTerminalConfig,...                            % terminalConfig
                range.Min,...                                   % minVal
                range.Max,...                                   % maxVal
                daq.ni.NIDAQmx.DAQmx_Val_Volts,...              % units
                char(0));                                       % customScaleName
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
    end
    
    % override the base class methods
    methods(Hidden)
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelAndCaptureParameters@daq.ni.AnalogInputVoltageChannel(taskHandle);
            obj.captureDSACommonChannelAttribFromNIDAQmx(taskHandle);
        end
        
        function onTaskRecreationHook(obj,taskHandle)
            obj.onDSATaskRecreationHook(taskHandle)
        end
    end
    
    methods (Access = protected)
        function DSAPropertyBeingChangedImpl(obj,propertyName,newValue)
            obj.DSAPropertyBeingChangedHook(propertyName,newValue,obj.Session)
        end

    end
end
