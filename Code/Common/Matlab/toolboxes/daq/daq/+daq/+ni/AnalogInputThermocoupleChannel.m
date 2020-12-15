classdef (Hidden) AnalogInputThermocoupleChannel < daq.AnalogInputChannel &  daq.ni.NICommonChannelAttrib 
    %AnalogInputThermocoupleChannel All settings & operations for an NI analog input thermocouple channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %Units The units to use to return the measurement.
        Units;
        
        %ThermocoupleType The type of thermocouple connected to the channel.
        ThermocoupleType;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputThermocoupleChannel(session,deviceInfo,channelID)
            %AnalogInputThermocoupleChannel All settings & operations for an analog input voltage thermocouple channel added to a session.
            %    AnalogInputThermocoupleChannel(SESSION,DEVICEINFO,CHANNELID) Create a
            %    analog channel with SESSION, DEVICEINFO,
            %    and CHANNELID
            
            % Create the channel to get appropriate defaults
            obj@daq.AnalogInputChannel(session,deviceInfo,channelID,'Volts');
            
            % NI-DAQmx refers to channels by "<device>/<channelID>"
            obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
            
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;
            
            obj.UnitsInfo            = daq.TemperatureUnits.Celsius;
            obj.ThermocoupleTypeInfo = daq.ThermocoupleType.Unknown;
            obj.Range                = daq.ni.utility.thermocoupleRange(obj.ThermocoupleTypeInfo,obj.UnitsInfo);
           
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogInput).OnDemandOperationsSupported;
           
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %Units The units to use to return thee measurement as an enumeration.
        UnitsInfo;
        
        %ThermocoupleTypeInfo The type of thermocouple connected to the channel as an enumeration.
        ThermocoupleTypeInfo;
    end
    
    % Property access methods
    methods
        function set.UnitsInfo(obj,newUnitsInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.UnitsInfo = newUnitsInfo;
                    obj.Units = char(newUnitsInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newUnitsInfo = daq.TemperatureUnits.setValue(newUnitsInfo);
                    obj.channelPropertyBeingChanged('UnitsInfo',newUnitsInfo)
                    % Keep the hidden and visible properties in sync
                    obj.UnitsInfo = newUnitsInfo;
                    obj.Units = char(newUnitsInfo);
                    obj.Range = daq.ni.utility.thermocoupleRange(obj.ThermocoupleTypeInfo,obj.UnitsInfo);
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
        
        function set.Units(obj,newUnits)
            try
                if obj.PropertyChangeInProgress
                    obj.Units = newUnits;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newUnitsInfo = daq.TemperatureUnits.setValue(newUnits);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('UnitsInfo',newUnitsInfo)
                    % Keep the hidden and visible properties in sync
                    obj.Units = char(newUnitsInfo);
                    obj.UnitsInfo = newUnitsInfo;
                    obj.Range = daq.ni.utility.thermocoupleRange(obj.ThermocoupleTypeInfo,obj.UnitsInfo);
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
        
        function set.ThermocoupleTypeInfo(obj,newThermocoupleTypeInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.ThermocoupleTypeInfo = newThermocoupleTypeInfo;
                    obj.ThermocoupleType = char(newThermocoupleTypeInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newThermocoupleTypeInfo = daq.ThermocoupleType.setValue(newThermocoupleTypeInfo);
                    obj.channelPropertyBeingChanged('ThermocoupleTypeInfo',newThermocoupleTypeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ThermocoupleTypeInfo = newThermocoupleTypeInfo;
                    obj.ThermocoupleType = char(newThermocoupleTypeInfo);
                    obj.Range = daq.ni.utility.thermocoupleRange(obj.ThermocoupleTypeInfo,obj.UnitsInfo);
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
        
        function set.ThermocoupleType(obj,newThermocoupleType)
            try
                if obj.PropertyChangeInProgress
                    obj.ThermocoupleType = newThermocoupleType;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newThermocoupleTypeInfo = daq.ThermocoupleType.setValue(newThermocoupleType);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('ThermocoupleTypeInfo',newThermocoupleTypeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ThermocoupleType = char(newThermocoupleTypeInfo);
                    obj.ThermocoupleTypeInfo = newThermocoupleTypeInfo;
                    obj.Range = daq.ni.utility.thermocoupleRange(obj.ThermocoupleTypeInfo,obj.UnitsInfo);
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
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelFirstTime(taskHandle)
        end
        
        function configureTask(obj,taskHandle)
            % Create the channel in NI-DAQmx
            obj.createChannel(taskHandle)
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
        
        function newRange = setRangeHook(obj,value)
            % Override standard set behavior for Range.  For thermocouple
            % channels, this property is read only, and driven by the
            % ThermocoupleType and Units property
            if ~obj.PropertyChangeInProgress
                obj.localizedError('nidaq:ni:thermocoupleRangeIsReadOnly');
            end
            
            obj.channelPropertyBeingChanged('Range',value)
            newRange = value;
        end    
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'Thermocouple';
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
                    case 'UnitsInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetAITempUnits(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'ThermocoupleTypeInfo'
                        obj.Range = daq.ni.utility.thermocoupleRange(newValue,obj.UnitsInfo);
                        obj.ThermocoupleTypeInfo = newValue;
                        obj.Session.recreateTaskHandle(obj.GroupName);                        
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
            
            % User is required to set bridge mode before starting
            if obj.ThermocoupleTypeInfo == daq.ThermocoupleType.Unknown
                obj.localizedError('nidaq:ni:mustSetThermocoupleType',obj.PhysicalChannel)
            end
            
        end
        
        function createChannelFirstTime(obj,taskHandle)
                obj.createChannel(taskHandle);
        end
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'analog input thermocouple channel';
        end
    end
    
    % Protected methods
    methods (Access = protected)
        function createChannel(obj,taskHandle)
            [status] = daq.ni.NIDAQmx.DAQmxCreateAIThrmcplChan(...
                taskHandle,...                          % taskHandle
                obj.PhysicalChannel,...                 % physicalChannel
                ' ',...                                 % nameToAssignToChannel
                obj.Range.Min,...                       % minVal
                obj.Range.Max,...                       % maxVal
                daq.ni.utility.DAQToNI(obj.UnitsInfo),...              % units
                daq.ni.utility.DAQToNI(obj.ThermocoupleTypeInfo),...   % thermocoupleType
                obj.DefaultCjcSource,...                % cjcSource
                obj.DefaultCjcVal,...                   % cjcVal
                obj.DefaultCjcChannel);                 % cjcChannel
            daq.ni.utility.throwOrWarnOnStatus(status);
         end
    end
    
    methods (Static, Hidden)
        function [isSupported] = detectIfSupported(device,knownGoodRange)
            isSupported = false;
            try
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                [status] = daq.ni.NIDAQmx.DAQmxCreateAIThrmcplChan(...
                    taskHandle,...                          % taskHandle
                    sprintf('%s/ai0',device),...            % physicalChannel
                    blanks(0),...                           % nameToAssignToChannel
                    knownGoodRange.Min,...                  % minVal
                    knownGoodRange.Max,...                  % maxVal
                    daq.ni.NIDAQmx.DAQmx_Val_DegC,...       % units
                    daq.ni.NIDAQmx.DAQmx_Val_J_Type_TC,...  % thermocoupleType
                    daq.ni.NIDAQmx.DAQmx_Val_BuiltIn,...    % cjcSource
                    0,...                                   % cjcVal
                    ' ');                                   % cjcChannel
                daq.ni.utility.throwOrWarnOnStatus(status);
                isSupported = true;
            catch  %#ok<CTCH>
                % Any error is failure
            end
            [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
        end
    end
    
    properties(Constant, GetAccess = private)
        %DefaultCjcSource The source of cold junction compensation.
        % Only devices that use a cold junction compensation channel that is
        % built into the terminal block are supported therefore this is
        % fixed at DAQmx_Val_BuiltIn.
        DefaultCjcSource = daq.ni.NIDAQmx.DAQmx_Val_BuiltIn;
        
        %DefaultCjcVal The temperature of the cold junction of the thermocouple
        %       if you set CjcSource to DAQmx_Val_ConstVal.
        % Since only built in CJC sources are supported this is fixed at 0.
        DefaultCjcVal = 0;
        
        %DefaultCjcChannel The channel that acquires the
        %temperature of the thermocouple cold-junction if you set cjcSource
        %to DAQmx_Val_Chan. You can use a global channel or another virtual
        %channel already in the task. If the channel is a temperature
        %channel, NI-DAQmx acquires the temperature in the correct units.
        %Other channel types, such as a resistance channel with a custom
        %sensor, must use a custom scale to scale values to degrees
        %Celsius.
        % Since only built in CJC sources are supported this is fixed at
        % a single blank.
        DefaultCjcChannel = ' ';
    end
    
end
