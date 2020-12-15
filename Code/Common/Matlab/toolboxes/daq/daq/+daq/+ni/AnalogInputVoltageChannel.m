classdef (Hidden) AnalogInputVoltageChannel < daq.AnalogInputVoltageChannel &...
        daq.ni.NICommonChannelAttrib 
    %AnalogInputVoltageChannel All settings & operations for an NI analog input voltage channel.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputVoltageChannel(session,deviceInfo,channelID)
            %AnalogInputVoltageChannel All settings & operations for an analog input voltage channel added to a session.
            %    AnalogInputVoltageChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.AnalogInputVoltageChannel(session,deviceInfo,channelID);
            
            % NI-DAQmx refers to channels by "<device>/<channelID>"
            obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogInput).OnDemandOperationsSupported;
           
        end
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelFirstTime(taskHandle)
            obj.captureAnalogInputVoltageParametersFromNIDAQmx(taskHandle)
            
            switch obj.TerminalConfig
                case 'Differential'
                    range = obj.Device.getSubsystem(daq.internal.SubsystemType.AnalogInput).RangesAvailableForDifferential;
                case 'SingleEnded'
                    range = obj.Device.getSubsystem(daq.internal.SubsystemType.AnalogInput).RangesAvailableForSingleEnded;
                case 'SingleEndedNonReferenced'
                    range = obj.Device.getSubsystem(daq.internal.SubsystemType.AnalogInput).RangesAvailableForSingleEndedNonReferenced;
                case 'PseudoDifferential'
                    range = obj.Device.getSubsystem(daq.internal.SubsystemType.AnalogInput).RangesAvailableForPseudoDifferential;                    
            end
          
            obj.SupportedRanges = range;
        end
        
        function configureTask(obj,taskHandle)
            % Create the channel in NI-DAQmx
            obj.createChannel(taskHandle,daq.ni.utility.DAQToNI(obj.TerminalConfigInfo),obj.Range)
            
            % Set the Coupling
            [status] = daq.ni.NIDAQmx.DAQmxSetAICoupling(...
                taskHandle,...
                obj.PhysicalChannel,...
                daq.ni.utility.DAQToNI(obj.CouplingInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group for this channel.
            %
            % The default implementation is to set the group name to
            % "ai/<DeviceID>" which causes all analog input channels from a
            % device to be grouped together.
            groupName = ['ai/' obj.Device.ID];
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
                obj.standardAIPropertyConfiguration(taskHandle,propertyName,newValue)
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
        
        function createChannelFirstTime(obj,taskHandle)
            [channelRange] = getSupportedRangeForDefaultChannelInputType(obj);
            % Set the object range to the supported range for the
            % particular channel input type
            obj.createChannel(taskHandle,daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default,channelRange);
            %Try to set the Range property of a channel. This will fail for
            %specialty measurements.
            obj.Range = channelRange;
        end
    end
    
    % Private methods
    methods (Access = protected)
        function createChannel(obj,taskHandle,niTerminalConfig,range)
            
            [status] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan (...
                taskHandle,...                                  % The task handle
                obj.PhysicalChannel,...                         % physicalChannel
                char(0),...                                     % nameToAssignToChannel
                niTerminalConfig,...                            % terminalConfig
                range.Min,...                               % minVal
                range.Max,...                               % maxVal
                daq.ni.NIDAQmx.DAQmx_Val_Volts,...              % units
                char(0));                                       % customScaleName
            daq.ni.utility.throwOrWarnOnStatus(status);
            % G748316: For some devices the DeviceInfo is unable to find
            % the correct supported measurement types. The call to 
            % daq.ni.NIDAQmx.DAQmxGetAIMeasType will fail if the channel 
            % was not created properly.
            % %G771829: Added condition to set the sample rate when 
            % checking for measurement type when creating channels.
            % (This exists because of the call added in G7483126)
            % G925662: Adding channels from different devices might not be
            % succesful if the first device supports on-demand operations
            % and the second does not. For example:
            % Add a channel from an NI 9215 (on-demand supported)
            % Add a channel from an NI 9234 (on-demand NOT supported)
            % The resulting 'InvalidAttributeValue' error can be ignored in
            % this and immediately subsequent cases.

            [status, ~] = daq.ni.NIDAQmx.DAQmxGetAIMeasType(taskHandle,obj.PhysicalChannel,int32(0));
            switch (status)
                case {daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd,...
                      daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue}
                    [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                        taskHandle,...
                        obj.Device.Subsystems.RateLimit(1));
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    
                    % If RateLimit(1) is 0, this will error
                    [status, ~] = daq.ni.NIDAQmx.DAQmxGetAIMeasType(taskHandle,obj.PhysicalChannel,int32(0));
                    if status == daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue
                        status = 0;
                    end
            end
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
    end
    
    methods( Access = private)
        function [channelRange] = getSupportedRangeForDefaultChannelInputType(obj)
            supportedRanges = obj.SupportedRanges;
            numSupportedRanges = numel(supportedRanges);
            
            % Default to highest range.
            channelRange = supportedRanges(numSupportedRanges);
            for iSupportedRanges = 0:(numSupportedRanges-1)

                % Create a Task
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                try
                    % Try creating channel with one of the supported ranges
                    [status] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan (...
                        taskHandle,...                                  % The task handle
                        obj.PhysicalChannel,...                         % physicalChannel
                        char(0),...                                     % nameToAssignToChannel
                        daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default,...                            % terminalConfig
                        supportedRanges(numSupportedRanges - iSupportedRanges).Min,...   % minVal
                        supportedRanges(numSupportedRanges - iSupportedRanges).Max,...   % maxVal
                        daq.ni.NIDAQmx.DAQmx_Val_Volts,...              % units
                        char(0));                                       % customScaleName
                    daq.ni.utility.throwOrWarnOnStatus(status);

                    % DAQmxGetAITermCfg requires that we set the
                    % clock for devices such as NI 9234
                    RateLimitInfo = obj.Device.getSubsystem(daq.internal.SubsystemType.AnalogInput).RateLimitInfo;
                    if RateLimitInfo.Max ~= 0
                        % Don't do this for on-demand only devices
                        [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(taskHandle, ...
                                                                      RateLimitInfo.Min);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    end

                    % If channel creation was unsuccessful, a read operation
                    % should error out
                    [readStatus,~] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
                        obj.PhysicalChannel, int32(0));                    
                    
                    % Clear the task before checking the readStatus 
                    status = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                    daq.ni.utility.throwOrWarnOnStatus(status);

                    if readStatus == daq.ni.NIDAQmx.DAQmxSuccess
                        channelRange = obj.SupportedRanges(numSupportedRanges - iSupportedRanges);
                        return;
                    end
                    
                catch e
                    % Make sure the task is cleaned up
                    [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                    rethrow(e)
                end
            end
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureAnalogInputVoltageParametersFromNIDAQmx(obj,taskHandle)
                      
            [status, AITermCfg] = GetNIDAQmxProperty(obj, taskHandle, 'AITermCfg');
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.TerminalConfig = daq.ni.utility.NIToDAQ(AITermCfg);
            
            % We don't know the Coupling: get it from NI-DAQmx
            [status,AICoupling] = GetNIDAQmxProperty(obj, taskHandle, 'AICoupling');
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.Coupling = daq.ni.utility.NIToDAQ(AICoupling);
            end
        end
        
        function [status, value] = GetNIDAQmxProperty(obj, taskHandle, property)
            % Capture the input type, get it from NI-DAQmx
            [status,value] = GetProperty(taskHandle, property);
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                return;
            end
            
            % G496133: Some devices require that the sample rate be set
            % before other operations. This will be indicated by the status
            % of the attempt to get the AITermCfg above. 
            %
            % G698695: In some scenarios, this property is unreadable
            % (e.g. Adding an NI-9201 AI voltage channel followed by an
            % NI-9234 accelerometer channel. This may be a sample timing
            % type problem.
            if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd ||...
               status == daq.ni.NIDAQmx.DAQmxErrorInvalidAttributeValue  
                [status] = daq.ni.NIDAQmx.DAQmxSetSampTimingType(...
                    taskHandle,...
                    daq.ni.NIDAQmx.DAQmx_Val_SampClk); %#ok<NASGU>
                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                    taskHandle,...
                    obj.Device.Subsystems.RateLimit(1)); %#ok<NASGU>
                [status,value] = GetProperty(taskHandle, property);
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    return;
                end
            end
            
            function [status, value] = GetProperty(taskHandle, property)
                switch property
                    case 'AITermCfg'
                        [status, value] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(...
                            taskHandle,...
                            obj.PhysicalChannel, int32(0));
                    case 'AICoupling'
                        [status, value] = daq.ni.NIDAQmx.DAQmxGetAICoupling(...
                            taskHandle,...
                            obj.PhysicalChannel, int32(0));
                    otherwise
                        obj.localizedError('daq:Session:unknownProperty',property)
                end
            end
        end
   end

    properties (Constant, GetAccess=private)
        DefaultCouplingInfo = daq.Coupling.DC;
    end
end
