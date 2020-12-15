classdef (Hidden) CounterOutputPulseGenerationChannel < daq.ni.CounterOutputPulseGenerationChannel
    %CounterOutputPulseGenerationChannel All settings &
    %operations for an NI CompactDAQ counter output PulseGeneration
    %channel.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterOutputPulseGenerationChannel(session,deviceInfo,channelID)
            %CounterOutputPulseGenerationChannel All settings &
            %operations for a CompactDAQ counter output PulseGeneration
            %channel added to a session.
            %    CounterOutputPulseGenerationChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)

            % Create the channel to get appropriate defaults
            obj@daq.ni.CounterOutputPulseGenerationChannel(session,deviceInfo,channelID);
       end
    end
end
