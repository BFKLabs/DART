classdef (Hidden) StateAcquiredDataWaiting < daq.internal.StateSession
    %StateAcquiredDataWaiting Hardware stopped, must get data from vendor
    %   StateAcquiredDataWaiting provides state specific behaviors for all
    %   operations when the Hardware is stopped, but there is input data still to
    %   be retrieved from the vendor implementation. It is assumed that
    %   some amount of data will come between the time the vendor called
    %   daq.Session.processAcquiredData and when it calls
    %   daq.Session.processHardwareStop.  The vendor must call
    %   daq.Session.processAcquiredData one final time to complete the
    %   retrieval of all data.  Note that this state cannot be reached when
    %   there are no input channels in the daq.Session.
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
        function obj = StateAcquiredDataWaiting(session)
            obj@daq.internal.StateSession(session);
        end
    end
    
    methods
        function [channel,index] = addChannel(obj,~) %#ok<STOUT>
            obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function [conn,index] = addTriggerConnection(obj,~) %#ok<STOUT>
             obj.localizedError('daq:Session:notWhileRunning');
        end
        
        function [conn,index] = addClockConnection(obj,~) %#ok<STOUT>
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
        
        function stop(obj,~) %#ok<MANU>
            % Calling stop is a no op
        end
        
        function queueOutputData(obj,~)
            obj.localizedError('daq:Session:stopInProgress');
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
            % Make sure all acquired data has been delivered
            obj.Session.emptyAcquisitionQueue()
            obj.Session.setIsDone(true)
            % Check if it is a multi-trigger operation
            if obj.Session.TriggersRemaining > 0
                % If yes, then start the operation again
                obj.Session.setIsDone(false);
                obj.Session.resetScanCounters();
                obj.Session.configSampleClockTiming();
                if obj.Session.SyncManager.configurationRequiresExternalTrigger()
                    obj.Session.changeState('WaitingForHardwareTrigger');
                else
                    obj.Session.changeState('HardwareRunning');
                end
                   obj.Session.startHardwareBetweenTriggers();                
            elseif obj.Session.Channels.countOutputChannels() > 0
                % If there's output channels, you'll need to queue data
                obj.Session.flushOutputData(false);
                obj.Session.changeState('NeedOutputDataAndPrepared')
            else
                % Otherwise, we're ready to go again
                obj.Session.changeState('ReadyToStartAndPrepared')
            end
        end
        
        function processHardwareTrigger(obj,varargin)
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareTrigger','AcquiredDataWaiting');
        end
        
        function processOutputEvent(obj,totalScansOutput)
            obj.Session.handleProcessOutputEvent(totalScansOutput);
        end
        
        function processHardwareStop(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareStop','AcquiredDataWaiting');
        end
        
        function result = getIsRunningFlag(~)
            result = true;
        end
        
        function result = getIsLoggingFlag(~)
            result = false;
        end
        
        function result = getIsWaitingForExternalTriggerFlag(~)
            result = false;
        end
        
        function dispSession(obj)
            obj.doDispWhenRunning();
        end
        
        function checkForTimeout(obj)
            obj.localizedError('daq:Session:badCommandInThisState','checkForTimeout','AcquiredDataWaiting');
        end
    end
    
end