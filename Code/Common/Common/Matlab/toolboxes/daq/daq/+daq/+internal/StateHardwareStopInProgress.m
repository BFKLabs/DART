classdef (Hidden) StateHardwareStopInProgress < daq.internal.StateSession
    %StateWaitingForHardwareTrigger Stop requested, but hardware still running
    %   StateWaitingForHardwareTrigger provides state specific behaviors for all
    %   operations when the session (or user) has requested a hardware
    %   stop, but the hardware has not yet reported the stop has occurred.
    %
    %    This undocumented class may be removed in a future release.
    
    %    2011 The MathWorks, Inc.

    %   Copyright 2010-2011 The MathWorks, Inc.
    
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
        function obj = StateHardwareStopInProgress(session)
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
        
        function stop(~,~)
            % Calling stop is a no op
        end
        
        function queueOutputData(obj,~)
            % Calling queueOutputData is a no op
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
        
        function processHardwareTrigger(~,~)
            % Calling processHardwareTrigger is a no op
        end
        
        function processOutputEvent(obj,totalScansOutput)
            obj.Session.handleProcessOutputEvent(totalScansOutput);
        end
        
        function processHardwareStop(obj,errorException)
            obj.Session.handleProcessHardwareStop(errorException);
            if obj.Session.Channels.countInputChannels() > 0
                % If there's input channels, you'll need to retrieve the
                % last of the data
                obj.Session.changeState('AcquiredDataWaiting')
            elseif obj.Session.Channels.countOutputChannels() > 0
                % If there's only output channels, user needs to queue more
                % data
                obj.Session.setIsDone(true)
                obj.Session.changeState('NeedOutputDataAndPrepared')
                obj.Session.flushOutputData(false);
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
              obj.localizedError('daq:Session:badCommandInThisState','checkForTimeout','HardwareStopInProgress');
        end
    end
    
end

