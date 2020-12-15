classdef (Hidden) CounterOutputChannel < daq.CounterOutputChannel & daq.ni.NICommonChannelAttrib
    %CounterOutputChannel settings & operations for an NI
    %counter Output channel.
    
    % Copyright 2010-2011 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterOutputChannel(session,deviceInfo,channelID)
            %CounterOutputChannel All settings & operations for a
            %counter Output channel added to a session.
            %    CounterOutputChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    counter channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.CounterOutputChannel(session,deviceInfo,channelID);
        end
    end
  
    methods (Hidden)
    end
end
