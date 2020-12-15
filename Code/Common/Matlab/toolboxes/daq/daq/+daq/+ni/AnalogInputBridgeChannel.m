classdef (Hidden) AnalogInputBridgeChannel < daq.AnalogInputChannel &  daq.ni.NICommonChannelAttrib
    %AnalogInputBridgeChannel All settings & operations for an NI analog
    %input bridge voltage channel.
    
    % Copyright 2011-2013 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    %Read/write properties
    properties
        %BridgeMode String specifying the bridge mode of
        %the channel. (quarter/half/full)
        % The number of active element legs in the Wheatstone bridge determines the kind of bridge mode.
        BridgeMode;
        
        %ExcitationSource Source for the excitation voltage (internal/external/none)
        ExcitationSource;
        
        %Excitation The desired excitation voltage for the channel in volts
        ExcitationVoltage;
        
        %NominalBridgeResistance The resistance of the bridge while not under load in ohms.
        NominalBridgeResistance;
    end
    
    properties (Hidden,SetAccess = private)
        AvailableInternalExcitationVoltages;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputBridgeChannel(session,deviceInfo,channelID)
            %AnalogInputBridgeChannel All settings & operations for an analog input voltage channel added to a session.
            
            obj@daq.AnalogInputChannel(session,deviceInfo,channelID,'VoltsPerVolt');
            
            % NI-DAQmx refers to channels by "<device>/<channelID>"
            obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
            
            % Set channel defaults
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress           = true;
            
            % Determine if there's internal excitation available
            obj.AvailableInternalExcitationVoltages = [];
            
            [arraysize, ~] = daq.ni.NIDAQmx.DAQmxGetDevAIVoltageIntExcitDiscreteVals(...
                deviceInfo.ID,...   % device
                0,...               % data
                uint32(0));         % arraySizeInElements
            if arraysize ~= 0
                [status, obj.AvailableInternalExcitationVoltages] = daq.ni.NIDAQmx.DAQmxGetDevAIVoltageIntExcitDiscreteVals(...
                    deviceInfo.ID,...       % device
                    zeros(1,arraysize),...  % data
                    uint32(arraysize));     % arraySizeInElements
                daq.ni.utility.throwOrWarnOnStatus(status);
                % Set the default to the minimum excitation value greater
                % than 0
                defaultExcitationVoltage = min(obj.AvailableInternalExcitationVoltages(obj.AvailableInternalExcitationVoltages > 0));
                dafaultExcitationSource = daq.ExcitationSource.Internal;
            else
                defaultExcitationVoltage = 0;
                dafaultExcitationSource = daq.ExcitationSource.None;
            end
            
            obj.ExcitationVoltage       = defaultExcitationVoltage;
            obj.ExcitationSource        = dafaultExcitationSource;
            obj.ExcitationSourceInfo    = daq.ExcitationSource.setValue(dafaultExcitationSource);
            
            obj.BridgeMode     = 'Unknown';
            obj.BridgeModeInfo = daq.BridgeMode.Unknown;
            
            obj.Range = daq.ni.utility.BridgeRange(obj.Device.Model,char(daq.BridgeMode.Quarter),obj.ExcitationVoltage);
            obj.NominalBridgeResistance = 'Unknown';
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogInput).OnDemandOperationsSupported;
           
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %BridgeMode Bridge Mode of a channel as an
        %enumeration
        BridgeModeInfo;
        
        %ExcitationSource Source for the excitation voltage as an
        %enumeration
        ExcitationSourceInfo;
    end
    
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function configureTask(obj,taskHandle)
            % Choosing a default value of 350 for nominalBridgeResistance
            % when it has not been currently set by the user.
            if strcmp(obj.NominalBridgeResistance,'Unknown')
                nominalBridgeResistance = 350;
            else
                nominalBridgeResistance = obj.NominalBridgeResistance;
            end
            
            obj.createChannel(taskHandle,nominalBridgeResistance)
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelFirstTime(taskHandle) 
        end
    end
    
    
    % Property access methods
    methods
        function set.BridgeMode(obj,newBridgeMode)
            try
                if obj.PropertyChangeInProgress
                    obj.BridgeMode = newBridgeMode;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newBridgeModeInfo = daq.BridgeMode.setValue(newBridgeMode);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('BridgeModeInfo',newBridgeModeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.BridgeMode = char(newBridgeModeInfo);
                    obj.BridgeModeInfo = newBridgeModeInfo;
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
        
        function set.BridgeModeInfo(obj,newBridgeModeInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.BridgeModeInfo = newBridgeModeInfo;
                    obj.BridgeMode = char(newBridgeModeInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    obj.lastGoodBridgeMode = obj.BridgeMode;
                    newBridgeModeInfo = daq.BridgMode.setValue(newBridgeModeInfo);
                    obj.channelPropertyBeingChanged('BridgeModeInfo',newBridgeModeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.BridgeModeInfo = newBridgeModeInfo;
                    obj.BridgeMode = char(newBridgeModeInfo);
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
        
        function set.ExcitationSource(obj,newExcitationSource)
            try
                if obj.PropertyChangeInProgress
                    obj.ExcitationSource = newExcitationSource;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    obj.lastGoodExcitationSource = obj.ExcitationSource;
                    newExcitationSourceInfo = daq.ExcitationSource.setValue(newExcitationSource);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('ExcitationSourceInfo',newExcitationSourceInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ExcitationSource = char(newExcitationSourceInfo);
                    obj.ExcitationSourceInfo = newExcitationSourceInfo;
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
        
        function set.ExcitationSourceInfo(obj,newExcitationSourceInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.ExcitationSourceInfo = newExcitationSourceInfo;
                    obj.ExcitationSource = char(newExcitationSourceInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newExcitationSourceInfo = daq.BridgMode.setValue(newExcitationSourceInfo);
                    obj.channelPropertyBeingChanged('ExcitationSourceInfo',newExcitationSourceInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ExcitationSourceInfo = newExcitationSourceInfo;
                    obj.ExcitationSource = char(newExcitationSourceInfo);
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
        
        function set.ExcitationVoltage(obj,newExcitationVoltage)
            try
                if obj.PropertyChangeInProgress
                    obj.ExcitationVoltage = newExcitationVoltage;
                    return
                end
                
                % Check that newExcitation is a scalar numeric greater than 0
                if isempty(newExcitationVoltage) || ~isscalar(newExcitationVoltage) ||...
                        ~daq.internal.isNumericNum(newExcitationVoltage) || newExcitationVoltage <= 0
                    obj.localizedError('nidaq:ni:invalidExcitationVoltage');
                end
                
                try
                    obj.PropertyChangeInProgress = true;
                    obj.lastGoodExcitationVoltage = obj.ExcitationVoltage;
                    obj.channelPropertyBeingChanged('ExcitationVoltage',newExcitationVoltage)
                    % Keep the hidden and visible properties in sync
                    obj.ExcitationVoltage = newExcitationVoltage;
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
        
        function set.NominalBridgeResistance(obj,newNominalBridgeResistance)
            try
                if obj.PropertyChangeInProgress
                    obj.NominalBridgeResistance = newNominalBridgeResistance;
                    return
                end
                
                % Check that newExcitation is a scalar numeric greater than 0
                if isempty(newNominalBridgeResistance) || ~isscalar(newNominalBridgeResistance) ||...
                        ~daq.internal.isNumericNum(newNominalBridgeResistance) || newNominalBridgeResistance <= 0
                    obj.localizedError('nidaq:ni:invalidNominalBridgeResistance');
                end
                
                try
                    obj.PropertyChangeInProgress = true;
                    obj.lastGoodNominalBridgeResistance = obj.NominalBridgeResistance;
                    obj.channelPropertyBeingChanged('NominalBridgeResistance',newNominalBridgeResistance)
                    % Keep the hidden and visible properties in sync
                    obj.NominalBridgeResistance = newNominalBridgeResistance;
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
    
    methods (Access = protected)
        
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group for this channel.
            %
            % The default implementation is to set the group name to
            % "ai/<DeviceID>" which causes all analog input channels from a
            % device to be grouped together.
            groupName = ['ai/' obj.Device.ID];
        end
        
        
        function newRange = setRangeHook(obj,value)
            % Override standard set behavior for Range.  
            if ~obj.PropertyChangeInProgress
                value = daq.Range(value(1),value(2),'VoltsPerVolt');
            end
            
            obj.channelPropertyBeingChanged('Range',value)
            newRange = value;
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
                    case 'BridgeModeInfo'
                        obj.Range = daq.ni.utility.BridgeRange(obj.Device.Model,char(newValue),obj.ExcitationVoltage);
                        obj.BridgeModeInfo = newValue;
                        obj.Session.recreateTaskHandle(obj.GroupName);
                        taskHandle = obj.Session.getUnreservedTaskHandle(obj.GroupName);
                        % If the property is not supported we will get an
                        % error on read
                        [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIBridgeCfg(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            int32(0));
                        if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd
                            [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                                taskHandle,...
                                obj.Device.Subsystems.RateLimit(1));
                            daq.ni.utility.throwOrWarnOnStatus(status);
                            
                            [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIBridgeCfg(...
                                taskHandle,...          % taskHandle
                                obj.PhysicalChannel,... % channel
                                int32(0));
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        if(readValue ~= newValue)
                            obj.BridgeMode = obj.lastGoodBridgeMode;
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'ExcitationSourceInfo'
                        % Trying to set
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIExcitSrc(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        % If the property is not supported we will get an
                        % error on read
                        [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIExcitSrc(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            int32(0));
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        if(readValue ~= newValue)
                            obj.ExcitationSource = obj.lastGoodExcitationSource;
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'NominalBridgeResistance'
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIBridgeNomResistance(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        % If the property is not supported we will get an
                        % error on read
                        [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIBridgeNomResistance(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            double(0));
                        if(readValue ~= newValue)
                            obj.NominalBridgeResistance = obj.lastGoodNominalBridgeResistance;
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'ExcitationVoltage'
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIExcitVal(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        % If the property is not supported we will get an
                        % error on read
                        [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIExcitVal(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            double(0));
                        if(readValue ~= newValue)
                            obj.ExcitationVoltage = obj.lastGoodExcitationVoltage;
                        end
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'Range'
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIMin(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue.Min);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIMax(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue.Max);
                        daq.ni.utility.throwOrWarnOnStatus(status);                        
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
            
            % User is required to set Bridge parameters before starting
            if strcmp(obj.BridgeMode, 'Unknown') && ...
               strcmp(obj.NominalBridgeResistance, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetBridgeParams',obj.PhysicalChannel)
            end
            
            if strcmp(obj.BridgeMode, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetBridgeConfig',obj.PhysicalChannel)
            end
            
            if strcmp(obj.NominalBridgeResistance, 'Unknown')
                obj.localizedError('nidaq:ni:mustSetNominalBridgeResistance',obj.PhysicalChannel)
            end
        end
            
        function channelInfoDisplayText = getChannelInfoDisplayHook(obj)
            % getChannelInfoDisplayHook A function that returns the string to
            % display the channel measurement type and other info in
            % the session display table
            channelInfoDisplayText = sprintf('%s (%s)', ...
                obj.getMeasurementTypeDisplayHook(),...
                obj.BridgeMode);            
        end
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'Bridge';
        end
        
        function createChannelFirstTime(obj,taskHandle)
            obj.createChannel(taskHandle,350);
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
    end
    
    methods (Static, Hidden)
        function [isSupported] = detectIfSupported(device,knownGoodRange)
            isSupported = false;
            safeExcitationValue = 0.1;
            safeNominalResistancevalue = 350;
           
            bridgeConf = {daq.ni.NIDAQmx.DAQmx_Val_FullBridge,...
                            daq.ni.NIDAQmx.DAQmx_Val_HalfBridge,...
                            daq.ni.NIDAQmx.DAQmx_Val_QuarterBridge };
                        
            for iBridgeConfig = 1:numel(bridgeConf)               
                try
                    [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    [status] = daq.ni.NIDAQmx.DAQmxCreateAIBridgeChan(...
                        taskHandle,...                              % taskHandle
                        sprintf('%s/ai0',device),...                % physicalChannel
                        blanks(0),...                               % nameToAssignToChannel
                        knownGoodRange.Min,...                      % minVal
                        knownGoodRange.Max,...                      % maxVal
                        daq.ni.NIDAQmx.DAQmx_Val_VoltsPerVolt,...   % units
                        bridgeConf{iBridgeConfig} ,...              % bridgeConfig
                        daq.ni.NIDAQmx.DAQmx_Val_Internal ,...      % voltageExcitSource
                        safeExcitationValue,...                     % voltageExcitVal
                        safeNominalResistancevalue,...              % nominalBridgeResistance
                        char(0));                                   % customScaleName
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    isSupported = true;
                    [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
                    break;
                catch  %#ok<CTCH>
                    % Any error is failure
                end
                [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
            end
        end
        
        function [supportedRanges] = getSupportedRanges(device)
            [supportedRanges] = daq.ni.utility.BridgeRange(device);
        end
        
    end
    
    % Private methods
    methods (Access = protected)
        function createChannel(obj,taskHandle,nominalBridgeResistance)
            [status] = daq.ni.NIDAQmx.DAQmxCreateAIBridgeChan(...
                taskHandle,...                              % taskHandle
                obj.PhysicalChannel,...                     % physicalChannel
                blanks(0),...                               % nameToAssignToChannel
                obj.Range.Min,...                           % minVal
                obj.Range.Max,...                           % maxVal
                daq.ni.NIDAQmx.DAQmx_Val_VoltsPerVolt,...   % units
                daq.ni.utility.DAQToNI(obj.BridgeModeInfo) ,...   % bridgeConfig
                daq.ni.utility.DAQToNI(obj.ExcitationSourceInfo),...       % voltageExcitSource
                obj.ExcitationVoltage,...                   % voltageExcitVal
                nominalBridgeResistance,...                 % nominalBridgeResistance
                char(0));                                   % customScaleName
            daq.ni.utility.throwOrWarnOnStatus(status);

        end
    end
    
    properties ( Hidden, Access = private)
        
        %lastGoodExcitationVoltage Last correct value is stored so that we
        %can restore if the driver errors on read
        lastGoodExcitationVoltage;
        
        %lastGoodExcitationSource Last correct value is stored so that we
        %can restore if the driver errors on read
        lastGoodExcitationSource;
        
        %lastGoodNominalBridgeResistance  Last correct value is stored so that we
        %can restore if the driver errors on read
        lastGoodNominalBridgeResistance;
        
        %lastGoodBridgeMode  Some devices like NI 9235/36 support only
        %Quarter bridge configuration. So store the last correct value for
        %restoration.
        lastGoodBridgeMode;
    end
    
end
