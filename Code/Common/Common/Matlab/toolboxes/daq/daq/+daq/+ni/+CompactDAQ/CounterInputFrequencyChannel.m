classdef (Hidden) CounterInputFrequencyChannel < daq.ni.CounterInputFrequencyChannel
    %CounterInputFrequencyChannel All settings & operations for
    %an NI CompactDAQ counter input Frequency channel.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputFrequencyChannel(session,deviceInfo,channelID)
            %CounterInputFrequencyChannel All settings &
            %operations for a CompactDAQ counter input Frequency channel
            %added to a session.
            %    CounterInputFrequencyChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)

            % Create the channel to get appropriate defaults
            obj@daq.ni.CounterInputFrequencyChannel(session,deviceInfo,channelID);
       end
    end
end
