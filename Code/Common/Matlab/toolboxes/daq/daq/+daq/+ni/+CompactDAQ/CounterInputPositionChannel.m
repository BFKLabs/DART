classdef (Hidden) CounterInputPositionChannel < daq.ni.CounterInputPositionChannel
    %CounterInputPositionChannel All settings & operations for an
    %NI CompactDAQ counter input Position channel.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputPositionChannel(session,deviceInfo,channelID)
            %CounterInputPositionChannel All settings &
            %operations for a CompactDAQ counter input Position channel
            %added to a session.
            %    CounterInputPositionChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)

            % Create the channel to get appropriate defaults
            obj@daq.ni.CounterInputPositionChannel(session,deviceInfo,channelID);
       end
    end
end
