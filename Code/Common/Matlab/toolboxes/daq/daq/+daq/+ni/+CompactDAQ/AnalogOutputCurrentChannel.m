classdef (Hidden) AnalogOutputCurrentChannel < daq.ni.AnalogOutputCurrentChannel
    %AnalogOutputCurrentChannel All settings & operations for an NI CompactDAQ analog output current channel.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogOutputCurrentChannel(session,deviceInfo,channelID)
            %AnalogOutputCurrentChannel All settings & operations for a CompactDAQ analog output current channel added to a session.
            %    CompactDAQAnalogOutputCurrentChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)

            % Create the channel to get appropriate defaults
            obj@daq.ni.AnalogOutputCurrentChannel(session,deviceInfo,channelID);
       end
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the group name for this channel.
            %
            % Override the default group name assignment.
            % The group name is "ao/<ChassisID>" which causes all analog
            % output channels from a chassis to be grouped together.
            groupName = ['ao/' obj.Device.ChassisName];
        end
    end
end
