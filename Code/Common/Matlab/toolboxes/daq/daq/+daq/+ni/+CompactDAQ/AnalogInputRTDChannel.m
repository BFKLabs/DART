classdef (Hidden) AnalogInputRTDChannel < daq.ni.AnalogInputRTDChannel & daq.ni.CompactDAQ.CommonAIChannelAttrib
    % AnalogInputRTDChannel All settings & operations
    %for an NI CompactDAQ analog input RTD channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj =  AnalogInputRTDChannel(session,deviceInfo,channelID)
            % AnalogInputRTDChannel All settings &
            %operations for a CompactDAQ analog input RTD channel
            %added to a session.
            %     AnalogInputRTDChannel(SESSION,DEVICEINFO,CHANNELID) Create a
            %    analog channel with SESSION, DEVICEINFO,
            %    and CHANNELID (see daq.Channel)

            % Create the channel to get appropriate defaults
            obj@daq.ni.AnalogInputRTDChannel(session,deviceInfo,channelID);
            obj@daq.ni.CompactDAQ.CommonAIChannelAttrib();
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
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelFirstTime(taskHandle);
            obj.BlockPropertyNotificationDuringInit = true;
            obj.captureADCTimingModeFromNIDAQmx(taskHandle,obj.Session);
            obj.BlockPropertyNotificationDuringInit = false;
            obj.captureAnalogInputRTDParametersFromNIDAQmx(taskHandle);
        end
        
        function configureTask(obj,taskHandle)
            obj.configureTask@daq.ni.AnalogInputRTDChannel(taskHandle);
            obj.configureADCTimingModeInTask(taskHandle);
        end
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the group name for this channel.
            %
            % Override the default group name assignment.
            % The group name is "ai/<ChassisID>" which causes all analog
            % input channels from a chassis to be grouped together.
            groupName = ['ai/' obj.Device.ChassisName];
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
            
            obj.channelPropertyBeingChangedHook@daq.ni.AnalogInputRTDChannel(propertyName,newValue);
            obj.compactDAQPropertyBeingChanged(propertyName,newValue,obj.Session);
        end
        
        function compactDAQChannelPropertyBeingChangedImpl(obj,propertyName,newValue)
            obj.channelPropertyBeingChanged(propertyName,newValue);
        end
        
        function [session] = getSession(obj)
            session = obj.Session;
        end        
    end
end
