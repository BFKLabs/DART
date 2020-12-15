classdef (Hidden) ChannelGroupStateNoTask < daq.ni.ChannelGroupState
    %ChannelGroupStateNoTask A ChannelGroup that does not have a NI-DAQmx task
    %    ChannelGroupStateNoTask Put your detailed info here
    
    % Copyright 2010-2011 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = ChannelGroupStateNoTask(taskGroup)
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
        function taskHandle = getUnreservedTaskHandle(obj)
            obj.ChannelGroup.doCreateTask();
            taskHandle = obj.ChannelGroup.doGetTaskHandle();
            obj.ChannelGroup.changeState('Unreserved')
        end
        
        function taskHandle = getCommittedTaskHandle(obj) %#ok<STOUT>
            % It's not legal to get an committed task handle when there is
            % no task.  It implies that something is out of sync -- we're
            % trying to run the task before we've configured it.
            obj.localizedError('nidaq:ni:badCommandInThisState','getTaskHandle','NoTask');
        end

        function configureForMultipleScans(obj)
            % It's not legal to do this when there is
            % no task.  It implies that something is out of sync -- we're
            % trying to run the task before we've configured it.
            obj.localizedError('nidaq:ni:badCommandInThisState','configureForMultipleScans','NoTask');
        end
        
        function updateNumberOfScans(obj)        
            obj.localizedError('nidaq:ni:badCommandInThisState','updateNumberOfScans','CommittedForSingleScan');
        end
        
        function configureForSingleScan(obj)
            % It's not legal to do this when there is
            % no task.  It implies that something is out of sync -- we're
            % trying to run the task before we've configured it.
            obj.localizedError('nidaq:ni:badCommandInThisState','configureForSingleScan','NoTask');
        end
        
        function configureForNextStart(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','configureForNextStart','NoTask');
        end
         
        function setup(obj)
            % It's not legal to setup or start when there is
            % no task.  It implies that something is out of sync -- we're
            % trying to run the task before we've configured it.
            obj.localizedError('nidaq:ni:badCommandInThisState','setup','NoTask');
        end
        
        function start(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','start','NoTask');
        end
        
        function stop(obj) %#ok<MANU>
            % Stop is a no-op in this state
        end
        
        function writeData(obj,dataToOutput) %#ok<INUSD>
            obj.localizedError('nidaq:ni:badCommandInThisState','writeData','NoTask');
        end
        
        function flush(obj) %#ok<MANU>
            % A no-op in this state
        end
        
        function unreserve(obj) %#ok<MANU>
            % A no-op in this state
        end
        
        function clearTask(obj) %#ok<MANU>
             % A no-op in this state
        end
        
        function result = getIsRunning(~)
            result = false;
        end
    end
    
    % Private methods
    methods (Access = private)
    end
end
