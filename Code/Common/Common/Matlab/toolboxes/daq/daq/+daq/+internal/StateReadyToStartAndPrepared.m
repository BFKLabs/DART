classdef (Hidden) StateReadyToStartAndPrepared < daq.internal.StateSession
    %StateReadyToStartAndPrepared Session is prepared and ready to run.
    %   StateReadyToStartAndPrepared provides state specific behaviors for all
    %   operations when the Session has been prepared and ready to run.
    %   All preconditions have been met, and the session is in a state
    %   where a call to daq.Session.startForeground() or
    %   daq.Session.startBackground() will result in a minimum latency
    %   operation.
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2010-2012 The MathWorks, Inc.
    
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
        function obj = StateReadyToStartAndPrepared(session)
            obj@daq.internal.StateSession(session);
        end
    end
    
    methods
        function [channel,index] = addChannel(obj,varargin)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % G687868: The unprepared state resulting from doRelease will
            % handle transitions to the on-demand only state (no state
            % transitions to on-demand only needed here)
            obj.goToUnpreparedState();
            
            % Call command again
            [channel,index] = obj.Session.addChannelInternal(varargin{:});
        end
        
        function [conn,index] = addTriggerConnection(obj,varargin)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % G687868: The unprepared state resulting from doRelease will
            % handle transitions to the on-demand only state (no state
            % transitions to on-demand only needed here)
            obj.goToUnpreparedState();
           
            [conn,index] = obj.Session.doAddTriggerConnection(varargin{:});
        end
        
        function [conn,index] = addClockConnection(obj,varargin)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % G687868: The unprepared state resulting from doRelease will
            % handle transitions to the on-demand only state (no state
            % transitions to on-demand only needed here)
            obj.goToUnpreparedState();
            
            [conn,index] = obj.Session.doAddClockConnection(varargin{:});
        end
        
        function removeChannel(obj,index)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Need to go to an unprepared state after a release operation.
            obj.goToUnpreparedState();
            
            % Call command again
            obj.Session.removeChannel(index)
        end
        
        function removeConnection(obj,index)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Need to go to an unprepared state after a release operation.
            obj.goToUnpreparedState();
            
            obj.Session.doRemoveConnection(index);
        end
        
        function errorIfParameterChangeNotOK(obj)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Need to go to an unprepared state after a release operation.
            obj.goToUnpreparedState();
            
            % Parameter changes are OK in this state now
        end
        
        function prepare(~)
            % Calling prepare is a no op
        end
        
        function [data, time, triggerTime] = startForeground(obj)
            obj.Session.setIsDone(false);
            obj.Session.resetScanCounters();
            obj.Session.configSampleClockTiming();
            if obj.Session.SyncManager.configurationRequiresExternalTrigger()
                obj.Session.changeState('WaitingForHardwareTrigger');
            else
                obj.Session.changeState('HardwareRunning');
            end
            try
                [data, time, triggerTime] = obj.Session.doStartForeground();
            catch e
                % Always go back to the same state if an error occurs
                obj.Session.changeState('ReadyToStartAndPrepared');
                rethrow(e)
            end
        end
        
        function startBackground(obj)
            obj.Session.setIsDone(false);
            obj.Session.resetScanCounters();
            obj.Session.configSampleClockTiming();
            if obj.Session.SyncManager.configurationRequiresExternalTrigger()
                obj.Session.changeState('WaitingForHardwareTrigger');
            else
                obj.Session.changeState('HardwareRunning');
            end
            try
                obj.Session.doStartBackground();
            catch e
                obj.Session.changeState('ReadyToStartAndPrepared')
                rethrow(e)
            end
        end
        
        function wait(~,~)
            % Calling wait is a no op
        end
        
        function stop(~,~)
            % Calling stop is a no op
        end
        
        function queueOutputData(obj,dataToOutput)
            obj.Session.doQueueOutputData(dataToOutput);
        end
        
        function resetCounters(obj)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Need to go to an unprepared state after a release operation.
            obj.goToUnpreparedState();
            
            obj.Session.doResetCounters();
        end
        
        function [data,triggerTime] = inputSingleScan(obj)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Need to go to an unprepared state after a release operation.
            obj.goToUnpreparedState();
            
            [data,triggerTime] = obj.Session.doInputSingleScan();
        end
        
        function outputSingleScan(obj,dataToOutput)
            % Warn the user that they have lost their prepared state
            obj.Session.doRelease(false);
            
            % Need to go to an unprepared state after a release operation.
            obj.goToUnpreparedState();
            
            obj.Session.doOutputSingleScan(dataToOutput);
        end
        
        function release(obj)
            obj.Session.doRelease(true);
            
            % Need to go to an unprepared state after a release operation.
            obj.goToUnpreparedState();
            
            % Call command again
        end
        
        function processAcquiredData(obj,~,~,~) %#ok<MANU>
            % Calling processAcquiredData is a no op (allows delayed done
            % event notifications without error)
        end
        
        function processHardwareTrigger(obj,varargin)
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareTrigger','ReadyToStartAndPrepared');
        end
        
        function processOutputEvent(obj,~) %#ok<MANU>
            % Calling processOutputEvent is a no op (allows delayed done
            % event notifications without error)
        end
        
        function processHardwareStop(obj,~) %#ok<MANU>
            % Calling processHardwareStop is a no op (allows delayed done
            % event notifications without error)
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
            % Calling checkForTimeout is a no op
        end
    end
    
    methods ( Access = private)
        function goToUnpreparedState(obj)
            if obj.Session.Channels.countOutputChannels() > 0
                % If there's output channels, you'll need to queue data
                obj.Session.changeState('NeedOutputData')
            else
                % If there's no output channels, you're OK to go
                obj.Session.changeState('ReadyToStart')
            end
        end
    end
end

