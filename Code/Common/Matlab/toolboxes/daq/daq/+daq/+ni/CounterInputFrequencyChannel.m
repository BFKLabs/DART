classdef (Hidden) CounterInputFrequencyChannel < daq.ni.CounterInputChannel
    %CounterInputFrequencyChannel All settings & operations for an NI
    %counter input Frequency channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties 
        %ActiveEdge Specifies the input signal edges (rising or falling) to
        %use when measuring frequency.
        ActiveEdge;
    end
    
    % Read only properties
    properties(SetAccess = protected)
        %Terminal Specifies the physical device frequency terminal
        Terminal;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputFrequencyChannel(session,deviceInfo,channelID)
            %CounterInputFrequencyChannel All settings & operations for an
            %counter input Frequency channel added to a session.
            %    CounterInputFrequencyChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    counter channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.CounterInputChannel(session,deviceInfo,channelID);
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
            
            % Set channel defaults
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;
            
            obj.Terminal = 'Unknown';
            
            % Hidden defaults
            obj.MinimumExpectedFreq = ...
                obj.Device.getSubsystem(daq.internal.SubsystemType.CounterInput).DefaultMinMaxExpectedFrequency(1);
            obj.MaximumExpectedFreq = ...
                obj.Device.getSubsystem(daq.internal.SubsystemType.CounterInput).DefaultMinMaxExpectedFrequency(2);
            obj.ActiveEdgeInfo = daq.SignalEdge.Rising;
            obj.UnitsInfo = daq.ni.NIDAQmx.DAQmx_Val_Hz;
            obj.MeasurementMethodInfo = daq.ni.NIDAQmx.DAQmx_Val_LowFreq1Ctr;
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.CounterInput).OnDemandOperationsSupportedFrequency;
       
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %MinimumExpectedFreq Minimum expected frequency value
        MinimumExpectedFreq;
        
        %MaximumExpectedFreq Maximum expected frequency value
        MaximumExpectedFreq;
        
        %ActiveEdgeInfo Enumeration specifies which input signal edges
        %(rising or falling) to measure frequency.
        ActiveEdgeInfo;
        
        %MeasurementMethodInfo Low frequency, high frequency or wide range
        MeasurementMethodInfo;
        
        %UnitsInfo Frequency units
        UnitsInfo;
    end
    
    methods
        function set.ActiveEdgeInfo(obj,newActiveEdgeInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.ActiveEdgeInfo = newActiveEdgeInfo;
                    obj.ActiveEdge = char(newActiveEdgeInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newActiveEdgeInfo = daq.SignalEdge.setValue(newActiveEdgeInfo);
                    obj.channelPropertyBeingChanged('ActiveEdgeInfo',newActiveEdgeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ActiveEdgeInfo = newActiveEdgeInfo;
                    obj.ActiveEdge = char(newActiveEdgeInfo);
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
        
        function set.ActiveEdge(obj,newActiveEdge)
            try
                if obj.PropertyChangeInProgress
                    obj.ActiveEdge = newActiveEdge;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newActiveEdgeInfo = daq.SignalEdge.setValue(newActiveEdge);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('ActiveEdgeInfo',newActiveEdgeInfo)
                    % Keep the hidden and visible properties in sync
                    obj.ActiveEdge = char(newActiveEdgeInfo);
                    obj.ActiveEdgeInfo = newActiveEdgeInfo;
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
        function configureTask(obj,taskHandle)
            obj.createChannel(taskHandle)
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCIFreqStartingEdge(...
                taskHandle,...
                obj.PhysicalChannel,...
                daq.ni.utility.DAQToNI(obj.ActiveEdgeInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannel(taskHandle);
            captureCounterInputFrequencyParametersFromNIDAQmx(obj,taskHandle)
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group name for this channel.
            %
            % The default implementation is to set GroupName to
            % "ci/PhysicalChannel" which causes all counter input channels
            % from a device to be grouped separately.
            groupName = ['ci/' obj.PhysicalChannel];
        end
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'Frequency';
        end
        
        function UpdateCounterOffsetHook(obj, ~) %#ok<MANU>
            % This counter channel does not keep track of counter offset
            % between start/stop counter operations
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
                    case 'ActiveEdgeInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCIFreqStartingEdge(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        daq.ni.utility.throwOrWarnOnStatus(status);
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
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'counter input frequency channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureCounterInputFrequencyParametersFromNIDAQmx(obj,taskHandle)
            % ActiveEdge
            [status,Edge] = daq.ni.NIDAQmx.DAQmxGetCICountEdgesActiveEdge(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.ActiveEdge = daq.ni.utility.NIToDAQ(Edge);
            end
        end
        
        function createChannel(obj,taskHandle)
            [status] = daq.ni.NIDAQmx.DAQmxCreateCIFreqChan (...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                char(0),...                             % nameToAssignToChannel
                obj.MinimumExpectedFreq,...             % minimum value
                obj.MaximumExpectedFreq,...             % maximum value
                obj.UnitsInfo,...                       % units
                daq.ni.utility.DAQToNI(obj.ActiveEdgeInfo),...         % active edge
                obj.MeasurementMethodInfo,...           % measurement method
                0,...                                   % measurement time for high freq.
                uint32(0),...                           % divisor for wide range
                char(0));                               % custom scale
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            BufferSize = 64;
            TerminalName = blanks(BufferSize);
            [status, TerminalName] = daq.ni.NIDAQmx.DAQmxGetCIFreqTerm(...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                TerminalName,...                        % buffer
                uint32(BufferSize));                    % buffer size
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            obj.Terminal = obj.abbreviateTerminalName(TerminalName);
        end
    end
end
