classdef (Hidden) DigitalBidirectionalChannel < daq.ni.DigitalBidirectionalChannel
    %DigitalChannel All settings & operations for an NI
    %CompactDAQ digital output channel.
    
    % Copyright 2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    methods(Hidden)
        function obj = DigitalBidirectionalChannel(session,deviceInfo,channelID)
            obj@daq.ni.DigitalBidirectionalChannel(session,deviceInfo,channelID);
       end
    end
    
    methods (Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group name to allow digital channels on a
            % CompactDAQ chassis to share the same task
            if strcmp(obj.Direction, 'Output')
                % Output
                groupName = ['do/'  obj.Device.ChassisName];
            else
                % Input or Unknown
                groupName = ['di/'  obj.Device.ChassisName];
            end
        end
    end
end
