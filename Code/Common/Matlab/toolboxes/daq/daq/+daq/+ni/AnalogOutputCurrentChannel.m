classdef (Hidden) AnalogOutputCurrentChannel < daq.AnalogOutputCurrentChannel & daq.ni.NICommonChannelAttrib
    %AnalogOutputCurrentChannel All settings & operations for an NI analog output current channel added to a session.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogOutputCurrentChannel(session,deviceInfo,channelID)
            %AnalogOutputCurrentChannel All settings & operations for an analog output voltage channel added to a session.
            %    AnalogOutputCurrentChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Voltage channels can only use Volts as a range
            obj@daq.AnalogOutputCurrentChannel(session,deviceInfo,channelID);
            
            % NI-DAQmx refers to channels by "<device>/<channelID>"
            obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
            
            % Get the group name.
            obj.GroupName = obj.getGroupNameHook();
           
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogOutput).OnDemandOperationsSupported;
           
        end
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function configureTask(obj,taskHandle)
            obj.createChannel(taskHandle)
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannel(taskHandle)
            obj.captureAnalogOutputCurrentParametersFromNIDAQmx(taskHandle)
        end
        
        function captureAnalogOutputCurrentParametersFromNIDAQmx(obj,taskHandle)
            % Capture the input type, get it from NI-DAQmx
            [status,AOTermCfg] = daq.ni.NIDAQmx.DAQmxGetAOTermCfg(taskHandle,...
                obj.PhysicalChannel, int32(0));
            % Check the status after insuring failure not caused by
            % need to set the sample rate first.
            
            % G639008 Some devices like the NI-9227 require the sample
            % timing type to be set to sample clocked before querying
            % properties like AITermCfg. G496133 Some devices like the
            % NI-9227 require that the sample rate be set before other
            % operations. This will be indicated by the status of the
            % attempt to get the AITermCfg above.
            if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd ||...
                status == daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue
            
                [status] = daq.ni.NIDAQmx.DAQmxSetSampTimingType(...
                    taskHandle,...
                    daq.ni.NIDAQmx.DAQmx_Val_SampClk);
                daq.ni.utility.throwOrWarnOnStatus(status);
            
                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                    taskHandle,...
                    obj.Device.Subsystems.RateLimit(1));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status,AOTermCfg] = daq.ni.NIDAQmx.DAQmxGetAOTermCfg(taskHandle,...
                    obj.PhysicalChannel, int32(0));
                % Check status outside if block
            end
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.TerminalConfig = daq.ni.utility.NIToDAQ(AOTermCfg);
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the group name for this channel.
            %
            % The default implementation is to set the group name to
            % "ai/<DeviceID>" which causes all analog input channels from a
            % device to be grouped together.
            groupName = ['ao/' obj.Device.ID];
        end
        
        function channelPropertyBeingChangedHook(obj,propertyName,newValue)
            % channelPropertyBeingChangedHook React to change in channel property.
            %
            % Provides the vendor the opportunity to react to changes in
            % channel properties.  Note that releaseHook() will be called
            % before this if needed.
            %
            % channelPropertyBeingChangedHook(PROPERTYNAME,NEWVALUE)
            % is called before property changes occur.  The vendor
            % implementation may throw an error to prevent the change, or
            % update their corresponding hardware session, if appropriate.
            % PROPERTYNAME is the name of the property to change and
            % NEWVALUE is the new value the property will have if this
            % function returns normally.
            
            taskHandle = obj.Session.getUnreservedTaskHandle(obj.GroupName);
            try
                obj.standardAOPropertyConfiguration(taskHandle,propertyName,newValue)
            catch e
                if isnumeric(newValue)
                    newValueChar = num2str(newValue);
                else
                    newValueChar = char(newValue);
                end
                
                % G642643 -- if the property has the 'Info' suffix, remove
                % it so that the message contains the customer facing
                % property name.  See also G656053
                propertyName(strfind(propertyName,'Info'):end) = [];

                switch e.identifier
                    case {'nidaq:ni:err200077','nidaq:ni:err200452'}
                        obj.localizedError('nidaq:ni:deviceDoesNotSupport',propertyName,newValueChar)
                    otherwise
                        rethrow(e)
                end
            end
        end
    end
    
    % Private methods
    methods (Access = private)
        function createChannel(obj,taskHandle)
            [status] = daq.ni.NIDAQmx.DAQmxCreateAOCurrentChan (...
                taskHandle,...                      % The task handle
                obj.PhysicalChannel,...             % physicalChannel
                char(0),...                         % nameToAssignToChannel
                obj.Range.Min,...                   % minVal
                obj.Range.Max,...                   % maxVal
                daq.ni.NIDAQmx.DAQmx_Val_Amps,...	% units
                char(0));                           % customScaleName
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % G748316: For some devices the DeviceInfo is unable to find
            % the correct supported measurement types. The following
            % NIDAQmx call will fail if the channel was not created
            % properly.
            [status, ~] = daq.ni.NIDAQmx.DAQmxGetAOOutputType(taskHandle,obj.PhysicalChannel,int32(0));
            if status ~= daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
        end
    end
end
