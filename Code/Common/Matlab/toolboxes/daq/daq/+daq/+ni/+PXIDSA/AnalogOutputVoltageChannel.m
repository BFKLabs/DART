classdef (Hidden) AnalogOutputVoltageChannel < daq.ni.AnalogOutputVoltageChannel
    %AnalogOutputVoltageChannel All settings & operations for an NI PXI DSA
    %analog output voltage channel.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogOutputVoltageChannel(session,deviceInfo,channelID)
            %AnalogOutputVoltageChannel All settings & operations for a CompactDAQ analog output voltage channel added to a session.
            %    AnalogOutputVoltageChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)

            % Create the channel to get appropriate defaults
            obj@daq.ni.AnalogOutputVoltageChannel(session,deviceInfo,channelID);
       end
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the group name for this channel.
            %
            % Override the default group name assignment.
            % The group name is based on the AutoSyncDSA property setting.
            % When AutoSyncDSA is true, all the PXI DSA boards in a session
            % need to be synchronized and are therefore put in a single NI
            % task. We do this by assigning it a common groupName which is
            % dependent on the PXI Chassis Number.
             if obj.Session.AutoSyncDSA
                groupName = ['ao/PXI' num2str(obj.Device.ChassisNumber)];
            else
                groupName = ['ao/' obj.Device.ID];
            end          
        end
    end
end
