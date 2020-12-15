classdef (Hidden) AnalogInputCurrentChannel < daq.AnalogInputCurrentChannel & daq.ni.NICommonChannelAttrib
    %AnalogInputCurrentChannel All settings & operations for an NI analog input current channel.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %ShuntLocation The location of the shunt resistor. Can be
        %external or internal
        ShuntLocation;
        
        %ShuntResistance The value, in ohms, of an external
        %shunt resistor.
        ShuntResistance;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputCurrentChannel(session,deviceInfo,channelID)
            %AnalogInputCurrentChannel All settings & operations for an analog input current channel added to a session.
            %    AnalogInputCurrentChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.AnalogInputCurrentChannel(session,deviceInfo,channelID);
            
            % NI-DAQmx refers to channels by "<device>/<channelID>"
            obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogInput).OnDemandOperationsSupported;
            
            obj.PropertyChangeInProgress = true;
            
            % Set the shunt resistance parameters to 'Unknown' as we will
            % get to know them after channel creation.
            obj.ShuntResistance = 'Unknown';
            obj.ShuntLocation = 'Default';
            obj.ShuntLocationInfo = daq.ShuntLocation.Default;
            
            obj.PropertyChangeInProgress = false;
            
        end
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function configureTask(obj,taskHandle)
            obj.createChannel(taskHandle,daq.ni.utility.DAQToNI(obj.TerminalConfigInfo))
            
            [status] = daq.ni.NIDAQmx.DAQmxSetAICoupling(taskHandle,obj.PhysicalChannel,daq.ni.utility.DAQToNI(obj.CouplingInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelFirstTime(taskHandle)
            obj.captureAnalogInputCurrentParametersFromNIDAQmx(taskHandle)
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group name for this channel.
            %
            % The default implementation is to set GroupName to
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
                switch propertyName
                    case 'ShuntLocationInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetAICurrentShuntLoc (...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'ShuntResistance'
                        obj.ShuntResistance = newValue;
                        try
                        obj.Session.recreateTaskHandle(obj.GroupName);
                        catch e
                            obj.ShuntResistance = obj.lastGoodShuntResistance;
                            obj.Session.recreateTaskHandle(obj.GroupName);
                            rethrow(e);
                        end
                        taskHandle = obj.Session.getUnreservedTaskHandle(obj.GroupName);
                        [status,shuntResistorValue] = daq.ni.NIDAQmx.DAQmxGetAICurrentShuntResistance(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            double(0));
                        if shuntResistorValue ~= newValue
                            obj.ShuntResistance = obj.lastGoodShuntResistance;
                            daq.ni.utility.throwOrWarnOnStatus(status);
                        end
                        
                            
                    otherwise
                        obj.standardAIPropertyConfiguration(taskHandle,propertyName,newValue)
                end
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
        
        function errorIfNotReadyToStartHook(obj)
            % errorIfNotReadyToStartHook Error if channel property is
            % invalid
            %
            % Provides the channel the opportunity to validate that all
            % settings are appropriate for an operation.
            %
            % errorIfNotReadyToStartHook() is called as part of prepare().
            % The vendor implementation may throw an error to prevent the
            % operation from going forward.
            %
            
            % User is required to set Shunt Resistance when Shunt Location
            % is External before starting
            if strcmp(obj.ShuntResistance, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetShuntResistance',obj.ID)
            end
            
        end
        
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function createChannelFirstTime(obj,taskHandle)
            obj.createChannel(taskHandle,daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default);
        end
        
        function captureAnalogInputCurrentParametersFromNIDAQmx(obj,taskHandle)
            % Capture the input type, get it from NI-DAQmx
            [status,AITermCfg] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
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
                
                [status,AITermCfg] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
                    obj.PhysicalChannel, int32(0));
                % Check status outside if block
            end
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.TerminalConfig = daq.ni.utility.NIToDAQ(AITermCfg);
            
            % We don't know the Coupling: get it from NI-DAQmx
            [status,AICoupling] = daq.ni.NIDAQmx.DAQmxGetAICoupling(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.Coupling = daq.ni.utility.NIToDAQ(AICoupling);
            end
            
            % We don't know the Shunt Resistor location: get it from NI-DAQmx
            [status,shuntLocation] = daq.ni.NIDAQmx.DAQmxGetAICurrentShuntLoc(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                if shuntLocation == daq.ni.NIDAQmx.DAQmx_Val_External
                    obj.ShuntLocationInfo = daq.ShuntLocation.External;
                else
                    obj.ShuntLocationInfo = daq.ShuntLocation.Internal;
                end
            end
            
            % We don't know the Shunt Resistor value: get it from NI-DAQmx
            obj.PropertyChangeInProgress = true;
            if  obj.ShuntLocationInfo == daq.ShuntLocation.Internal;
                [status,shuntResistorValue] = daq.ni.NIDAQmx.DAQmxGetAICurrentShuntResistance(...
                    taskHandle,...
                    obj.PhysicalChannel,...
                    double(0));
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    obj.ShuntResistance = shuntResistorValue;
                end
            end
            obj.PropertyChangeInProgress = false;
        end
    end
    
    % Private methods
    methods (Access = private)
        function createChannel(obj,taskHandle,niTerminalConfig)
            if strcmp(obj.ShuntResistance,'Unknown')
                shuntResistance = 1e-6;
            else
                shuntResistance = obj.ShuntResistance;
            end
            
            [status] = daq.ni.NIDAQmx.DAQmxCreateAICurrentChan (...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                char(0),...                             % nameToAssignToChannel
                niTerminalConfig,...                    % terminalConfig
                obj.Range.Min,...                       % minVal
                obj.Range.Max,...                       % maxVal
                daq.ni.NIDAQmx.DAQmx_Val_Amps,...       % units
                daq.ni.utility.DAQToNI(obj.ShuntLocationInfo),...	    % shuntResistorLoc
                shuntResistance,...                     % extShuntResistorVal
                char(0));                               % customScaleName
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % G748316: For some devices the DeviceInfo is unable to find
            % the correct supported measurement types. The following
            % NIDAQmx call will fail if the channel was not created
            % properly.
            [status ~] = daq.ni.NIDAQmx.DAQmxGetAIMeasType(taskHandle,obj.PhysicalChannel,int32(0));
            if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd
                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                    taskHandle,...
                    obj.Device.Subsystems.RateLimit(1));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status ~] = daq.ni.NIDAQmx.DAQmxGetAIMeasType(taskHandle,obj.PhysicalChannel,int32(0));
                % Check status outside if block
            end
            daq.ni.utility.throwOrWarnOnStatus(status);
            
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %ShuntLocationInfo The location of the shunt resistor as an
        %enum
        ShuntLocationInfo
    end
    
    methods
        function set.ShuntLocationInfo(obj,value)
            try
                if obj.PropertyChangeInProgress
                    obj.ShuntLocationInfo = value;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newValue = daq.ShuntLocation.setValue(value);
                    obj.channelPropertyBeingChanged('ShuntLocationInfo',newValue)
                    % Keep the hidden and visible properties in sync
                    obj.ShuntLocationInfo = newValue;
                    obj.ShuntLocation = char(newValue);
                    obj.PropertyChangeInProgress = false;
                catch e
                    obj.PropertyChangeInProgress = false;
                    rethrow(e)
                end
            catch e
                % Rethrow any errors as caller, removing the long stack of
                % errors -- capture the full exception in the cause field
                % if FullDebug option is set.
                if daq.internal.getOptions().FullDebug
                    rethrow(e);
                end
                e.throwAsCaller()
            end
        end
        
        function set.ShuntLocation(obj,value)
            try
                if obj.PropertyChangeInProgress
                    obj.ShuntLocation = value;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newValue = daq.ShuntLocation.setValue(value);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('ShuntLocationInfo',newValue)
                    % Keep the hidden and visible properties in sync
                    obj.ShuntLocation = char(newValue);
                    obj.ShuntLocationInfo = newValue;
                    obj.PropertyChangeInProgress = false;
                catch e
                    obj.PropertyChangeInProgress = false;
                    rethrow(e)
                end
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
        
        function set.ShuntResistance(obj,newShuntResistance)
            try
                if obj.PropertyChangeInProgress
                    obj.ShuntResistance = newShuntResistance;
                    return
                end
                
                if obj.ShuntLocationInfo == daq.ShuntLocation.Internal
                    obj.localizedError('nidaq:ni:cannotSetShuntResistanceWhenInternal');
                end
                
                if strcmp(newShuntResistance,'Unknown')
                    obj.ShuntResistance = newShuntResistance;
                    return
                end
                % Check that newShuntResistance is a scalar numeric greater than 0
                if isempty(newShuntResistance) || ~isscalar(newShuntResistance) ||...
                        ~daq.internal.isNumericNum(newShuntResistance) || newShuntResistance <= 0
                    obj.localizedError('nidaq:ni:invalidShuntResistance');
                end
                
                try
                    obj.PropertyChangeInProgress = true;
                    obj.lastGoodShuntResistance = obj.ShuntResistance;
                    obj.channelPropertyBeingChanged('ShuntResistance',newShuntResistance)
                    % Keep the hidden and visible properties in sync
                    obj.ShuntResistance = newShuntResistance;
                    obj.PropertyChangeInProgress = false;
                catch e
                    obj.PropertyChangeInProgress = false;
                    rethrow(e)
                end
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
    end
    
    properties ( Hidden, Access = private)
        lastGoodShuntResistance;
    end
end
