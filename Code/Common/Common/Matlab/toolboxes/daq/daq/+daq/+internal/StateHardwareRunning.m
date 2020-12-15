classdef (Hidden) StateHardwareRunning < daq.internal.StateSession
    %StateHardwareRunning Session and hardware are running.
    %   StateHardwareRunning provides state specific behaviors for all
    %   operations when the Session and hardware are running.
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
        function obj = StateHardwareRunning(session)
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
            obj.Session.decrementTriggersRemaining();
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
        
        function processAcquiredData(obj,triggerTime,timestamps,dataAcquired)
            obj.Session.handleProcessAcquiredData(triggerTime,timestamps,dataAcquired);
        end
        
        function processHardwareTrigger(~,varargin)
            % Trigger being received when the session is already running is a no op
        end
        
        function processOutputEvent(obj,totalScansOutput)
            obj.Session.handleProcessOutputEvent(totalScansOutput);
        end
        
        function processHardwareStop(obj,errorException)
            obj.Session.decrementTriggersRemaining();
            obj.Session.handleProcessHardwareStop(errorException);
            
            % Requeue data for multi-trigger acquisitions.
            if obj.Session.Channels.countOutputChannels() > 0 &&...
                    obj.Session.TriggersRemaining > 0
                obj.Session.requeueOutputData();
            end
            
            if obj.Session.Channels.countInputChannels() > 0
                % If there's input channels, you'll need to retrieve the
                % last of the data
                obj.Session.changeState('AcquiredDataWaiting')
            elseif obj.Session.Channels.countOutputChannels() > 0
                % Check if it is a multi-trigger operations
                if obj.Session.TriggersRemaining > 0
                    % If yes, we need to start again
                    obj.Session.setIsDone(false);
                    obj.Session.resetScanCounters();
                    obj.Session.configSampleClockTiming();
                    if obj.Session.SyncManager.configurationRequiresExternalTrigger()
                        obj.Session.changeState('WaitingForHardwareTrigger');
                    else
                        obj.Session.changeState('HardwareRunning');
                    end
                    obj.Session.startHardwareBetweenTriggers();
                else
                    % If there's only output channels, user needs to queue more
                    % data
                    obj.Session.setIsDone(true)
                    obj.Session.changeState('NeedOutputDataAndPrepared')
                    obj.Session.flushOutputData(false);
                end
            else
                % If there's only counter output channels, user does not
                % need to queue data
                obj.Session.setIsDone(true)
                obj.Session.changeState('ReadyToStartAndPrepared')
            end
            
        end
        
        function result = getIsRunningFlag(~)
            result = true;
        end
        
        function result = getIsLoggingFlag(~)
            result = true;
        end
        
        function result = getIsWaitingForExternalTriggerFlag(~)
            result = false;
        end
        
        function dispSession(obj)
            obj.doDispWhenRunning();
        end
        
        function checkForTimeout(obj)
            % Wait for up to 10% longer than the expected duration, plus 1
            % second
            try
                timeout = obj.Session.DurationInSeconds + ...
                    obj.Session.StartForegroundTimeoutPercentage +...
                    obj.Session.StartForegroundTimeoutAdditional;
                obj.Session.doWait(timeout * obj.Session.TriggersPerRun);
            catch e
                rethrow(e)
            end
        end
    end
    
end

