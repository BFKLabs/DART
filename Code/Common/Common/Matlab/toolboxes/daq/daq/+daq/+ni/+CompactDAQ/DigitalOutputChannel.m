classdef (Hidden) DigitalOutputChannel < daq.ni.DigitalOutputChannel
    %DigitalChannel All settings & operations for an NI
    %CompactDAQ digital output channel.
    
    % Copyright 2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    methods(Hidden)
        function obj = DigitalOutputChannel(session,deviceInfo,channelID)
            obj@daq.ni.DigitalOutputChannel(session,deviceInfo,channelID);
       end
    end
    
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group name to allow digital channels on a
            % CompactDAQ chassis to share the same task
            groupName = ['do/'  obj.Device.ChassisName];
        end
    end
end
