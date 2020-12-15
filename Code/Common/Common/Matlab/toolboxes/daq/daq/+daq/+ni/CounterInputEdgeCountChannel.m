classdef (Hidden) CounterInputEdgeCountChannel < daq.ni.CounterInputChannel
    %CounterInputEdgeCountChannel All settings & operations for an NI
    %counter input EdgeCount channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %ActiveEdge Specifies the input signal edges (rising or falling) to
        %count.
        ActiveEdge;
        
        %CountDirection Specifies whether to increment or decrement the
        %counter on input signal edges.
        CountDirection;
        
        %InitialCount Specifies the starting count value
        InitialCount;
    end
    
    % Read only properties
    properties(SetAccess = protected)
        %Terminal Specifies the physical device edge count terminal
        Terminal;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputEdgeCountChannel(session,deviceInfo,channelID)
            %CounterInputEdgeCountChannel All settings & operations for an
            %counter input EdgeCount channel added to a session.
            %    CounterInputEdgeCountChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    counter channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.CounterInputChannel(session,deviceInfo,channelID);
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();

            % Set channel defaults
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;
            obj.ChannelCreationInProgress = true;

            obj.InitialCount        = 0;
            obj.ActiveEdgeInfo      = daq.SignalEdge.setValue( ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.CounterInput).DefaultActiveEdge);
            obj.CountDirectionInfo  = daq.CountDirection.Increment;
            obj.Terminal            = 'Unknown';
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.CounterInput).OnDemandOperationsSupportedEdgeCount;
       
            obj.ChannelCreationInProgress = false;
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %ActiveEdgeInfo Enumeration specifies which input signal edges (rising or
        %falling) to count.
        ActiveEdgeInfo;
        
        %CountDirectionInfo Enumeration specifies whether to increment or
        %decrement the counter on input signal edges.
        CountDirectionInfo;
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
                    obj.internalResetCounter();
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
        
        function set.CountDirectionInfo(obj,newCountDirectionInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.CountDirectionInfo = newCountDirectionInfo;
                    obj.CountDirection = char(newCountDirectionInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newCountDirectionInfo = daq.CountDirection.setValue(newCountDirectionInfo);
                    obj.channelPropertyBeingChanged('CountDirectionInfo',newCountDirectionInfo)
                    % Keep the hidden and visible properties in sync
                    obj.CountDirectionInfo = newCountDirectionInfo;
                    obj.CountDirection = char(newCountDirectionInfo);
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
        
        function set.CountDirection(obj,newCountDirection)
            try
                if obj.PropertyChangeInProgress
                    obj.CountDirection = newCountDirection;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newCountDirectionInfo = daq.CountDirection.setValue(newCountDirection);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('CountDirectionInfo',newCountDirectionInfo)
                    % Keep the hidden and visible properties in sync
                    obj.CountDirection = char(newCountDirectionInfo);
                    obj.CountDirectionInfo = newCountDirectionInfo;
                    obj.PropertyChangeInProgress = false;
                    obj.internalResetCounter();
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
        
        function set.InitialCount(obj,newInitialCount)
            try
                newInitialCount = uint32(newInitialCount);
                obj.channelPropertyBeingChanged('InitialCount',newInitialCount)
                obj.InitialCount = newInitialCount;
                obj.internalResetCounter();
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
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCICountEdgesInitialCnt(...
                taskHandle,...
                obj.PhysicalChannel,...
                obj.InitialCount);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCICountEdgesActiveEdge(...
                taskHandle,...
                obj.PhysicalChannel,...
                daq.ni.utility.DAQToNI(obj.ActiveEdgeInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            [status] = daq.ni.NIDAQmx.DAQmxSetCICountEdgesDir(...
                taskHandle,...
                obj.PhysicalChannel,...
                daq.ni.utility.DAQToNI(obj.CountDirectionInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.ChannelCreationInProgress = true;
            obj.createChannel(taskHandle);
            captureCounterInputEdgeCountParametersFromNIDAQmx(obj,taskHandle)
            obj.ChannelCreationInProgress = false;
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
            measurementTypeDisplayText = 'EdgeCount';
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
                    case 'InitialCount'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCICountEdgesInitialCnt(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            newValue);
                        daq.ni.utility.throwOrWarnOnStatus(status);
                    case 'ActiveEdgeInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCICountEdgesActiveEdge(...
                            taskHandle,...          % taskHandle
                            obj.PhysicalChannel,... % channel
                            daq.ni.utility.DAQToNI(newValue));
                        daq.ni.utility.throwOrWarnOnStatus(status);
                   case 'CountDirectionInfo'
                        [status] = daq.ni.NIDAQmx.DAQmxSetCICountEdgesDir(...
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
            channelDescriptionText = 'counter input edge count channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureCounterInputEdgeCountParametersFromNIDAQmx(obj,taskHandle)
            % InitialCount
            [status,initialCount] = daq.ni.NIDAQmx.DAQmxGetCICountEdgesInitialCnt(...
                taskHandle,...
                obj.PhysicalChannel,...
                uint32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.InitialCount = initialCount;
            end
            
            % ActiveEdge
            [status,Edge] = daq.ni.NIDAQmx.DAQmxGetCICountEdgesActiveEdge(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.ActiveEdge = daq.ni.utility.NIToDAQ(Edge);
            end
            
            % CountDirection
            [status,countDirection] = daq.ni.NIDAQmx.DAQmxGetCICountEdgesDir(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.CountDirection = daq.ni.utility.NIToDAQ(countDirection);
            end
        end
        
        function createChannel(obj,taskHandle)
            [status] = daq.ni.NIDAQmx.DAQmxCreateCICountEdgesChan (...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                char(0),...                             % nameToAssignToChannel
                daq.ni.utility.DAQToNI(obj.ActiveEdgeInfo),...         % active edge
                uint32(obj.InitialCount),...            % initial count
                daq.ni.utility.DAQToNI(obj.CountDirectionInfo));       % count direction
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            BufferSize = 64;
            TerminalName = blanks(BufferSize);
            [status, TerminalName] = daq.ni.NIDAQmx.DAQmxGetCICountEdgesTerm(...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                TerminalName,...                        % buffer
                uint32(BufferSize));                    % buffer size
            if status == 0
                obj.Terminal = obj.abbreviateTerminalName(TerminalName);
            end
        end
    end
end
