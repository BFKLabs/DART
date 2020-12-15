classdef (Hidden) CounterInputChannel < daq.CounterInputChannel & daq.ni.NICommonChannelAttrib
    %CounterInputChannel settings & operations for an NI
    %counter input channel.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputChannel(session,deviceInfo,channelID)
            %CounterInputChannel All settings & operations for a
            %counter input channel added to a session.
            %    CounterInputChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    counter channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.CounterInputChannel(session,deviceInfo,channelID);
        end
    end
        
    methods
        function resetCounter(obj)
            % Reset the counter
            obj.Session.configureForSingleScan(obj.GroupName);
            taskHandle = obj.Session.getCommittedTaskHandle(obj.GroupName);
            [status] = daq.ni.NIDAQmx.DAQmxStopTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
            [status] = daq.ni.NIDAQmx.DAQmxStartTask(taskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
    end
    
    % Protected properties
    properties(SetAccess = protected, GetAccess = protected)
        % Internal property that handle internal reset counters
        ChannelCreationInProgress
    end
    
    methods(Access = public, Hidden)
        function internalResetCounter(obj)
            try
                if ~obj.ChannelCreationInProgress
                    obj.resetCounter();
                end
            catch e 
                if ~strcmp(e.identifier, 'nidaq:ni:badCommandInThisState') &&...
                   ~strcmp(e.identifier, 'nidaq:ni:err200478') % Channels not created yet
                    rethrow(e);
                end
            end
        end
    end
    
    methods (Hidden)
    end
end
