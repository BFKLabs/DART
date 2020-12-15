classdef (Hidden) DigitalInputChannel < daq.ni.DigitalChannel
    %DigitalInputChannel All settings & operations for an NI digital input
    %channel.
    
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
        function obj = DigitalInputChannel(session,deviceInfo,channelID)
            %DigitalInputChannel All settings & operations for a digital
            %input channel added to a session.
            %    DigitalInputChannel(SESSION,DEVICEINFO,ID,MEASUREMENTTYPE)
            %    Create a digital input channel with SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
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
            
            obj.Direction = char(daq.Direction.Input);
            
            subsystem = deviceInfo.getSubsystem(daq.internal.SubsystemType.DigitalIO);
            obj.OnDemandOperationsSupported = subsystem.OnDemandOperationsSupported;
            
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
        end

        function configureTask(obj,taskHandle)
            obj.createChannel(taskHandle)
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannel(taskHandle);
            obj.captureDigitalChannelParametersFromNIDAQmx(taskHandle)
        end
        
        % Should be protected friend
        function channelDescriptionText = getChannelDescriptionHook(~)
                channelDescriptionText = 'digital input channel';
        end
    end
    
    methods
        function set.Direction(obj,newDirection)
            if obj.PropertyChangeInProgress
                obj.Direction = newDirection;
                return
            end
            
            obj.localizedError('daq:Channel:readOnlyPropertyForChannelByMeasType',...
                'Direction', 'digital', 'InputOnly', 'Bidirectional');
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            groupName = ['di/'  obj.Device.ID];
        end
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(~)
            measurementTypeDisplayText = 'InputOnly';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureDigitalChannelParametersFromNIDAQmx(obj,taskHandle)
            virtualChannelName = obj.PhysicalChannel;
            if obj.isGroup
                virtualChannelName = obj.ID;
            end

            % Update GroupChannelCount property
            [status,numLines] = daq.ni.NIDAQmx.DAQmxGetDINumLines(...
                taskHandle,...
                virtualChannelName,...
                uint32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.GroupChannelCount = double(numLines);
            end
        end
        
        function createChannel(obj,taskHandle)
            virtualChannelName = char(0);
            if obj.isGroup
                virtualChannelName = obj.ID;
            end
            
            % Create digital input channel
            [status] = daq.ni.NIDAQmx.DAQmxCreateDIChan (...
                taskHandle,...                          % The task handle
                obj.PhysicalChannel,...                 % physicalChannel
                virtualChannelName,...                  % nameToAssignToChannel
                daq.ni.NIDAQmx.DAQmx_Val_ChanForAllLines); % channel grouping
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
    end
end
