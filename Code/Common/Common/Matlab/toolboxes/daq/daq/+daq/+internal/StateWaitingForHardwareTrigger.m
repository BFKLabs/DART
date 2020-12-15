classdef (Hidden) StateWaitingForHardwareTrigger < daq.internal.StateSession
    %StateWaitingForHardwareTrigger Session running, operation paused until hardware trigger occurs.
    %   StateWaitingForHardwareTrigger provides state specific behaviors for all
    %   operations when the Session is running, but operation is paused
    %   until a hardware trigger is received.
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2010-2011 The MathWorks, Inc.
    
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
        function obj = StateWaitingForHardwareTrigger(session)
            obj@daq.internal.StateSession(session);
        end
    end
    
    methods
        function [channel,index] = addChannel(obj,varargin) %#ok<STOUT>
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function [conn,index] = addTriggerConnection(obj,varargin) %#ok<STOUT>
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function [conn,index] = addClockConnection(obj,varargin) %#ok<STOUT>
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function removeChannel(obj,~)
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function removeConnection(obj,~)
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function errorIfParameterChangeNotOK(obj)
            e = obj.getLocalizedException('daq:Session:noChangeWhileRunning');
            e.throwAsCaller();
        end
        
        function prepare(obj)
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function [data, time, triggerTime] = startForeground(obj) %#ok<STOUT>
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function startBackground(obj)
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function wait(obj,timeout)
            obj.Session.doWait(timeout);
        end
        
        function stop(obj,noWait)
            obj.Session.changeState('HardwareStopInProgress')
            try
                obj.Session.doStop(noWait);
            catch e
                % If the stop fails, we generate a hardware stop event to
                % force the state machine to stopped state, and fire the
                % ErrorOccurred event
                obj.processHardwareStop(e)
                rethrow(e)
            end
        end
        
        function queueOutputData(obj,dataToOutput)
            if ~obj.Session.IsContinuous
                obj.localizedError('daq:Session:requiresContinuousMode');
            end
            obj.Session.doQueueOutputData(dataToOutput);
        end
        
        function resetCounters(obj)
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function [data,triggerTime] = inputSingleScan(obj) %#ok<STOUT>
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function outputSingleScan(obj,~)
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function release(obj)
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function processAcquiredData(obj,varargin)
            obj.localizedError('daq:Session:badCommandInThisState','processAcquiredData','WaitingForHardwareTrigger');
        end
        
        function processHardwareTrigger(obj,varargin)
            obj.Session.changeState('HardwareRunning')           
        end
        
        function processOutputEvent(obj,varargin)
            obj.localizedError('daq:Session:badCommandInThisState','processOutputEvent','WaitingForHardwareTrigger');
        end
        
        function processHardwareStop(obj,errorException)
            obj.Session.handleProcessHardwareStop(errorException)
            obj.Session.changeState('ReadyToStart')
        end
        
        function result = getIsRunningFlag(~)
            result = true;
        end
        
        function result = getIsLoggingFlag(~)
            result = false;
        end
        
        function result = getIsWaitingForExternalTriggerFlag(~)
            result = true;
        end
        
        function dispSession(obj)
            obj.doDispWhenRunning();
        end
        
        function checkForTimeout(obj)
            % The session will first wait for the start trigger to arrive; it will wait
            % for the time specified in ExternalTriggerTimeout and then it will wait for
            % the session to complete its regular acquisition.
            try
                % Wait for up to 10% longer than the expected duration, plus 1
                % second
                timeout = obj.Session.DurationInSeconds + ...
                obj.Session.StartForegroundTimeoutPercentage +...
                obj.Session.StartForegroundTimeoutAdditional + ...
                obj.Session.ExternalTriggerTimeout;
                obj.Session.doWait(timeout * obj.Session.TriggersPerRun);                
            catch e
                if strcmp(e.identifier,'daq:Session:timeout')
                    % Recast error to a more appropriate one for timeout
                    obj.localizedError('daq:Session:externalTriggerTimeout')
                end
                rethrow(e)
            end

        end
    end
    
end

