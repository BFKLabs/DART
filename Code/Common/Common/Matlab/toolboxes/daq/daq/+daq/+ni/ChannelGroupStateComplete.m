classdef (Hidden) ChannelGroupStateComplete < daq.ni.ChannelGroupState
    %ChannelGroupStateComplete A ChannelGroup that does not have a NI-DAQmx task
    %    ChannelGroupStateComplete Put your detailed info here
    
    % Copyright 2010-2011 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = ChannelGroupStateComplete(taskGroup)
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

        function configureForMultipleScans(obj)
            obj.ChannelGroup.doConfigureForMultipleScans();
            obj.ChannelGroup.changeState('CommittedForMultipleScans')
        end
        
        function updateNumberOfScans(obj)        
            obj.localizedError('nidaq:ni:badCommandInThisState','updateNumberOfScans','CommittedForSingleScan');
        end
        
        function configureForSingleScan(obj)
            obj.ChannelGroup.doConfigureForSingleScan();
            obj.ChannelGroup.changeState('CommittedForSingleScan')
        end
        
        function configureForNextStart(obj)
            obj.ChannelGroup.changeState('CommittedForMultipleScans')
        end
         
        function setup(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','setup','Complete');
        end
        
        function start(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','start','Complete');
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
