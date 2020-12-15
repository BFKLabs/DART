classdef (Hidden) ChannelGroupStateCommittedForMultipleScans < daq.ni.ChannelGroupState
    %ChannelGroupStateCommittedForMultipleScans A ChannelGroup that does not have a NI-DAQmx task
    %    ChannelGroupStateCommittedForMultipleScans Put your detailed info here
    
    % Copyright 2010-2011 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = ChannelGroupStateCommittedForMultipleScans(taskGroup)
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
            obj.ChannelGroup.doUnreserve();
            taskHandle = obj.ChannelGroup.doGetTaskHandle();
            obj.ChannelGroup.changeState('Unreserved')
        end
        
        function taskHandle = getCommittedTaskHandle(obj)
            taskHandle = obj.ChannelGroup.doGetTaskHandle();
        end

        function configureForMultipleScans(obj) %#ok<MANU>
            % a no-op in this state
        end
        
        function updateNumberOfScans(obj)        
            obj.ChannelGroup.doUpdateNumberOfScans();
        end
        
        function configureForSingleScan(obj)
            try
                obj.ChannelGroup.doConfigureForSingleScan();
                obj.ChannelGroup.changeState('CommittedForSingleScan')
            catch e
                obj.ChannelGroup.changeState('CommittedForMultipleScans')
                throw(e)
            end
        end
        
        function configureForNextStart(obj) %#ok<MANU>
            % a no-op in this state
        end
         
        function setup(obj)
            try
                obj.ChannelGroup.doSetup();
            catch e
                obj.ChannelGroup.handleStop(e);
            end
        end
        
        function start(obj)
            try
                obj.ChannelGroup.changeState('Running')
                obj.ChannelGroup.doStart();
            catch e
                obj.ChannelGroup.handleStop(e);
            end
        end
        
        function stop(obj) %#ok<MANU>
            % Stop is a no-op in this state
        end
        
        function writeData(obj,dataToOutput)
            obj.ChannelGroup.doWriteData(dataToOutput);
        end
        
        function flush(obj)
            obj.ChannelGroup.doFlush();
        end
        
        function unreserve(obj)
            obj.ChannelGroup.doUnreserve();
            obj.ChannelGroup.changeState('Unreserved')
        end
        
        function clearTask(obj)
            obj.ChannelGroup.doClearTask();
            obj.ChannelGroup.changeState('NoTask')
        end
        
        function result = getIsRunning(~)
            result = false;
        end
    end
    
    % Private methods
    methods (Access = private)
    end
end
