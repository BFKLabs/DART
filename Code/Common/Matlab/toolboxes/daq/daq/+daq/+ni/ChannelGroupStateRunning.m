classdef (Hidden) ChannelGroupStateRunning < daq.ni.ChannelGroupState
    %ChannelGroupStateRunning A ChannelGroup that does not have a NI-DAQmx task
    %    ChannelGroupStateRunning Put your detailed info here
    
    % Copyright 2010-2011 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = ChannelGroupStateRunning(taskGroup)
            obj@daq.ni.ChannelGroupState(taskGroup);
        end
    end
    
    %% -- Public methods, properties, and events --
    %% -- Protected and private members of the class --
    % Private properties
    properties (GetAccess = private,SetAccess = private)
    end

    % Internal constants
    properties(Constant, GetAccess = private)
    end
    
    methods
        function taskHandle = getUnreservedTaskHandle(obj) %#ok<STOUT>
            % It's not legal to get an unreserved task handle while we're
            % running.  It implies that something is out of sync -- we're
            % trying to change the task while it is acquiring data
            obj.localizedError('nidaq:ni:badCommandInThisState','getUnreservedTaskHandle','Running');
        end
        
        function taskHandle = getCommittedTaskHandle(obj)
            taskHandle = obj.ChannelGroup.doGetTaskHandle();
        end

        function configureForMultipleScans(obj)
            % It's not legal to get an unreserved task handle while we're
            % running.  It implies that something is out of sync -- we're
            % trying to change the task while it is acquiring data
            obj.localizedError('nidaq:ni:badCommandInThisState','configureForMultipleScans','Running');
        end
        
        function updateNumberOfScans(obj)        
            obj.localizedError('nidaq:ni:badCommandInThisState','updateNumberOfScans','CommittedForSingleScan');
        end
        
        function configureForSingleScan(obj)
            % It's not legal to get an unreserved task handle while we're
            % running.  It implies that something is out of sync -- we're
            % trying to change the task while it is acquiring data
            obj.localizedError('nidaq:ni:badCommandInThisState','configureForSingleScan','Running');
        end
        
        function configureForNextStart(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','configureForNextStart','Running');
        end
         
        function setup(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','setup','Running');
        end
        
        function start(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','start','Running');
        end
        
        function stop(obj)
            obj.ChannelGroup.doStop();
            obj.ChannelGroup.changeState('Complete')
        end
        
        function writeData(obj,dataToOutput)
            obj.ChannelGroup.doWriteData(dataToOutput);
        end
        
        function flush(obj)
            obj.ChannelGroup.doFlush();
        end
        
        function unreserve(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','unreserve','Running');
        end
        
        function clearTask(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','clearTask','Running');
        end
        
        function result = getIsRunning(~)
            result = true;
        end
    end
    
    % Private methods
    methods (Access = private)
    end
end
