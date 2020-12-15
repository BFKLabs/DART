classdef (Hidden) CounterInputPulseWidthChannel < daq.ni.CounterInputPulseWidthChannel
    %CounterInputPulseWidthChannel All settings & operations for
    %an NI CompactDAQ counter input PulseWidth channel.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputPulseWidthChannel(session,deviceInfo,channelID)
            %CounterInputPulseWidthChannel All settings &
            %operations for a CompactDAQ counter input PulseWidth channel
            %added to a session.
            %    CounterInputPulseWidthChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)

            % Create the channel to get appropriate defaults
            obj@daq.ni.CounterInputPulseWidthChannel(session,deviceInfo,channelID);
       end
    end
end
