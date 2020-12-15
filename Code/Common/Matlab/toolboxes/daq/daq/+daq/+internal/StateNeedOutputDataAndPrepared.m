classdef (Hidden) StateNeedOutputDataAndPrepared < daq.internal.StateSession
    %StateNeedOutputDataAndPrepared Session has run once, no data has been queued for next cycle.
    %   StateNeedOutputDataAndPrepared provides state specific behaviors
    %   for all operations when the Session has output channels, has been
    %   run once, and is ready to run again, except that data to output for
    %   the next run has not been queued using
    %   daq.Session.queueOutputData().
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2010-2013 The MathWorks, Inc.
     
    %   See the Data Acquisition Toolbox CompactDAQ architecture spec, geck
    %   35908, for a complete state charts and descriptions of the states.
    %
    %   This class functions as a State for the Data Acquisition Toolbox
    %   daq.Session object, as defined by "Design Patterns," Booch, et all.
    %   It implements state-specific behaviors on the behalf of the
    %   daq.Session object.  The advantage of this are:
    %
    %   1. The Session object does not have large switch statements or
    %      conditional logic based on current state, reducing the
    %      cyclomatic complexity of the Session class enormously.
    %
    %   2. State operations are 100% internally consistent, reducing the
    %      opportunities for state-based logic errors.  Adding a state is
    %      straightforward.
    %
    %   3. All state based logic for a given state is here in the state
    %      class, allowing easy changes to the state behavior
    
    % Constructor
    methods
        function obj = StateNeedOutputDataAndPrepared(session)
            obj@daq.internal.StateSession(session);
        end
    end
    
    methods
        function [channel,index] = addChannel(obj,varargin)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Put into NeedOutputData, and call again
            obj.Session.changeState('NeedOutputData')
            [channel,index] = obj.Session.addChannelInternal(varargin{:});
        end
        
        function [conn,index] = addTriggerConnection(obj,varargin)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
        
            % Put into NeedOutputData, and call again
            obj.Session.changeState('NeedOutputData')
            [conn,index] = obj.Session.doAddTriggerConnection(varargin{:});
        end
        
        function [conn,index] = addClockConnection(obj,varargin) 
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Put into NeedOutputData, and call again
            obj.Session.changeState('NeedOutputData')
            [conn,index] = obj.Session.doAddClockConnection(varargin{:});
        end 
        
        function removeChannel(obj,index)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Put into NeedOutputData, and call again
            obj.Session.changeState('NeedOutputData')
            obj.Session.removeChannel(index)
        end
        
        function removeConnection(obj,index)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Put into NeedOutputData, and call again
            obj.Session.changeState('NeedOutputData')            
            obj.Session.doRemoveConnection(index);
        end
        
        function errorIfParameterChangeNotOK(obj)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);

            % Put into NeedOutputData state
            obj.Session.changeState('NeedOutputData')
            % Parameter changes are OK in this state now
        end
        
        function prepare(~)
            % Calling prepare is a no op
        end
        
        function [data, time, triggerTime] = startForeground(obj)  %#ok<STOUT>
            obj.localizedError('daq:Session:noDataQueued');
        end
        
        function startBackground(obj)
            obj.localizedError('daq:Session:noDataQueued');
        end
        
        function wait(~,~)
            % Calling wait is a no op
        end
        
        function stop(~,~)
            % Calling stop is a no op
        end
        
        function queueOutputData(obj,dataToOutput)
            obj.Session.setIsDone(false);
            obj.Session.resetScanCounters();             
            obj.Session.doQueueOutputData(dataToOutput);
            obj.Session.changeState('ReadyToStartAndPrepared')
        end
        
        function resetCounters(obj)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
          
            % Put into NeedOutputData, and call again
            obj.Session.changeState('NeedOutputData')
     
            obj.Session.doResetCounters();
        end
        
        function [data,triggerTime] = inputSingleScan(obj)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
     
            % Put into NeedOutputData, and call again
            obj.Session.changeState('NeedOutputData')
          
            [data,triggerTime] = obj.Session.doInputSingleScan();
        end
        
        function outputSingleScan(obj,dataToOutput)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Put into NeedOutputData, and call again
            obj.Session.changeState('NeedOutputData')
                 
            obj.Session.doOutputSingleScan(dataToOutput);
        end
        
        function release(obj)
            obj.Session.doRelease(true);
            obj.Session.changeState('NeedOutputData')
        end

        function processAcquiredData(obj,~,~,~)
            obj.Session.emptyAcquisitionQueue();
        end
        
        function processHardwareTrigger(~,~)
            % Calling processHardwareTrigger is a no op
        end
        
        function processOutputEvent(obj,totalScansOutput)
            obj.Session.handleProcessOutputEvent(totalScansOutput);
        end
        
        function processHardwareStop(obj,error)
            if ~isempty(error)
                obj.localizedWarning('daq:Session:errorEventOccurredAfterStop',error.message);
            end
        end
        
        function result = getIsRunningFlag(~)
            result = false;
        end
        
        function result = getIsLoggingFlag(~)
            result = false;
        end
		
        function result = getIsWaitingForExternalTriggerFlag(~)
            result = false;
        end

	    function dispSession(obj)
			obj.doDispWhenIdle();
        end
        
        function checkForTimeout(~)
            % Calling checkForTimeout is a no-op because a Session does 
            % not, on the basis of state, determine whether an operation 
            % was started in the foreground or the background.
            % Whereas it is not valid to end up in this state immediately
            % after a background hardware operation starts, it is perfectly
            % valid for a foreground operation to end up here upon
            % completion, as characterized by the following intermediate
            % conditions:
            % IsLogging =   False 
            % IsDone =      True
            % IsRunning =   False
            %
            % Therefore, in the foreground, this operation should do
            % nothing.
        end

    end
    
end