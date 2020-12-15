classdef (Hidden) ChannelGroupStateUnreserved < daq.ni.ChannelGroupState
    %ChannelGroupStateUnreserved A ChannelGroup that does not have a NI-DAQmx task
    %    ChannelGroupStateUnreserved Put your detailed info here
    
    % Copyright 2010-2011 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = ChannelGroupStateUnreserved(taskGroup)
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
            taskHandle = obj.ChannelGroup.doGetTaskHandle();
        end
        
        function taskHandle = getCommittedTaskHandle(obj)
            obj.configureForSingleScan();
            taskHandle = obj.ChannelGroup.doGetTaskHandle();
        end

        function configureForMultipleScans(obj)
            try
                obj.ChannelGroup.doConfigureForMultipleScans();
                obj.ChannelGroup.changeState('CommittedForMultipleScans')
            catch e
                obj.ChannelGroup.doUnreserve();
                obj.ChannelGroup.changeState('Unreserved');
                throw(e)
            end
        end
        
        function updateNumberOfScans(obj)        
            obj.localizedError('nidaq:ni:badCommandInThisState','updateNumberOfScans','CommittedForSingleScan');
        end
        
        function configureForSingleScan(obj)
            try
                obj.ChannelGroup.doConfigureForSingleScan();
                obj.ChannelGroup.changeState('CommittedForSingleScan')
            catch e
                obj.ChannelGroup.doUnreserve();
                obj.ChannelGroup.changeState('Unreserved');
                throw(e)
            end
        end
        
        function configureForNextStart(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','configureForNextStart','Unreserved');
        end
         
        function setup(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','setup','Unreserved');
        end
        
        function start(obj)
            obj.localizedError('nidaq:ni:badCommandInThisState','start','Unreserved');
        end
       
        function stop(obj) %#ok<MANU>
            % Stop is a no-op in this state
        end
        
        function writeData(obj,dataToOutput) %#ok<INUSD>
            obj.localizedError('nidaq:ni:badCommandInThisState','writeData','Unreserved');
        end
        
        function flush(obj) %#ok<MANU>
            % a no-op in this state
        end
        
        function unreserve(obj) %#ok<MANU>
            % a no-op in this state
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
