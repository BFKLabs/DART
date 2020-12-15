classdef (Hidden) DigitalBidirectionalChannel < daq.ni.DigitalChannel
    %DigitalChannel All settings & operations for an NI digital
    %bidirectional channel.
    
    % Copyright 2012-2013 The MathWorks, Inc.
    %
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public properties --
    % Read/write properties
    properties
        Direction;
    end
    
    % Should be a protected friend
    properties(Hidden, SetAccess = private)
        IsGroup;
        GroupChannelIDs;
        GroupChannelCount;
    end

    %% -- Public methods --
    methods(Hidden)
        function obj = DigitalBidirectionalChannel(session,deviceInfo,channelID)
            %DigitalChannel All settings & operations for a digital
            %bidirectional channel added to a session.
            %    DigitalChannel(SESSION,DEVICEINFO,ID) Create a digital
            %    bidirectional channel with SESSION, DEVICEINFO, and ID
            %    (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.DigitalChannel(session,deviceInfo,channelID);
            
            % Set channel defaults
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;
            
            if iscell(channelID)
                obj.IsGroup = true;
                obj.GroupChannelCount = numel(channelID);
                obj.GroupChannelIDs = channelID;
            else
                obj.IsGroup = false;
                obj.GroupChannelCount = 1;
                obj.GroupChannelIDs = {channelID};
            end
            
            obj.DirectionInfo = daq.Direction.Unknown; % User required property
            
            subsystem = deviceInfo.getSubsystem(daq.internal.SubsystemType.DigitalIO);
            obj.OnDemandOperationsSupported = subsystem.OnDemandOperationsSupported;
            
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %DirectionInfo Enumeration specifies DIO terminal direction.
        DirectionInfo;
    end
    
    methods
        function set.DirectionInfo(obj,newDirectionInfo)
            try
                if obj.PropertyChangeInProgress
                    obj.DirectionInfo = newDirectionInfo;
                    obj.Direction = char(newDirectionInfo);
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newDirectionInfo = daq.Direction.setValue(newDirectionInfo);
                    % Keep the hidden and visible properties in sync
                    obj.DirectionInfo = newDirectionInfo;
                    obj.Direction = char(newDirectionInfo);
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
        
        function set.Direction(obj,newDirection)
            try
                if obj.PropertyChangeInProgress
                    obj.Direction = newDirection;
                    return
                end
                
                newDirection = char(newDirection);
                
                try
                    obj.PropertyChangeInProgress = true;
                    direction = obj.getCorrectDirectionCapitalization(newDirection);
                    if ~isempty(direction)
                        newDirectionInfo = daq.Direction.setValue(direction);
                        % Really, we only change the underlying hidden property
                        % with the enumeration -- and we only report that change
                        % Keep the hidden and visible properties in sync
                        obj.Direction = char(direction);
                        obj.DirectionInfo = newDirectionInfo;
                        obj.GroupName = obj.getGroupNameHook();
                        obj.Session.recreateAllChannelGroups();
                        obj.PropertyChangeInProgress = false;
                    else
                        obj.PropertyChangeInProgress = false;
                        obj.localizedError('daq:Channel:unsupportedDevicePropertyValue',...
                            obj.Device.Model,'Direction',newDirection);
                    end
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
    
    %% Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function configureTask(obj,taskHandle)
            obj.createChannel(taskHandle)
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannel(taskHandle);
            obj.captureDigitalChannelParametersFromNIDAQmx(taskHandle)
        end
        
        function channelDescriptionText = getChannelDescriptionHook(obj)
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            if obj.DirectionInfo == daq.Direction.Input
                channelDescriptionText = 'digital bidirectional (input) channel';
            elseif obj.DirectionInfo == daq.Direction.Output
                channelDescriptionText = 'digital bidirectional (output) channel';
            else
                channelDescriptionText = 'digital bidirectional (unknown) channel';
            end
        end
    end
    
    %% Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group name for this channel.
            if obj.DirectionInfo == daq.Direction.Output
                % Output
                groupName = ['do/'  obj.Device.ID];
            else
                % Input or Unknown
                groupName = ['di/'  obj.Device.ID];
            end
        end
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj)
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = ['Bidirectional (' obj.Direction ')'];  
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
            
            % User is required to set microphone sensitivity before starting
            if strcmp(obj.Direction, 'Unknown')
                obj.localizedError('daq:Channel:unsetPropertyForChannelByMeasType',...
                    'Direction', 'digital', 'Bidirectional');
            end
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureDigitalChannelParametersFromNIDAQmx(obj,taskHandle)
            virtualChannelName = obj.PhysicalChannel;
            if obj.isGroup
                virtualChannelName = obj.ID;
            end
            
            if obj.DirectionInfo == daq.Direction.Output
                % GroupChannelCount
                [status,numLines] = daq.ni.NIDAQmx.DAQmxGetDONumLines(...
                    taskHandle,...
                    virtualChannelName,...
                    uint32(0));
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    obj.GroupChannelCount = double(numLines);
                end
            else
                % Direction: Input/Unknown
                % GroupChannelCount
                [status,numLines] = daq.ni.NIDAQmx.DAQmxGetDINumLines(...
                    taskHandle,...
                    virtualChannelName,...
                    uint32(0));
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    obj.GroupChannelCount = double(numLines);
                end
            end
        end
        
        function createChannel(obj,taskHandle)
            virtualChannelName = char(0);
            if obj.isGroup
                virtualChannelName = obj.ID;
            end
            
            if obj.DirectionInfo == daq.Direction.Output
                [status] = daq.ni.NIDAQmx.DAQmxCreateDOChan (...
                    taskHandle,...                          % The task handle
                    obj.PhysicalChannel,...                 % physicalChannel
                    virtualChannelName,...                  % nameToAssignToChannel
                    daq.ni.NIDAQmx.DAQmx_Val_ChanForAllLines);  % channel grouping
                daq.ni.utility.throwOrWarnOnStatus(status);
            else
                % Direction: Input/Unknown
                [status] = daq.ni.NIDAQmx.DAQmxCreateDIChan (...
                    taskHandle,...                          % The task handle
                    obj.PhysicalChannel,...                 % physicalChannel
                    virtualChannelName,...                  % nameToAssignToChannel
                    daq.ni.NIDAQmx.DAQmx_Val_ChanForAllLines);  % channel grouping
                daq.ni.utility.throwOrWarnOnStatus(status);
            end
        end
    end

    %% Helper method for Direction property case correction
    methods(Access = private)
        function [result] = getCorrectDirectionCapitalization(~, newDirection)
            result = [];
            if strcmpi(newDirection, char(daq.Direction.Input))
                result = char(daq.Direction.Input);
            elseif strcmpi(newDirection, char(daq.Direction.Output))
                result = char(daq.Direction.Output);
            end
        end
    end
end
