classdef (Hidden) StateReadyToStart < daq.internal.StateSession
    %StateReadyToStart Session is ready to be started or prepared.
    %   StateReadyToStart provides state specific behaviors for all
    %   operations when the Session is ready to be started or prepared, and
    %   all preconditions have been met.
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
        function obj = StateReadyToStart(session)
            obj@daq.internal.StateSession(session);
        end
    end
    

    methods
        function [channel,index] = addChannel(obj,varargin)
            [channel,index] = obj.Session.doAddChannel(varargin{:});
            if obj.Session.RateLimit(2) == 0
                % G687868: Session contains a device that does not support
                % clocked sampling. Only on-demand operations using
                % inputSingleScan and outputSingleScan can be done.
                obj.localizedWarning('daq:Session:onDemandOnlyChannelsAdded');
                obj.Session.changeState('OnDemandOnly')
            elseif obj.Session.Channels.countOutputChannels() > 0 &&...
                    obj.Session.ScansQueued == 0
                % If there's output channels, you'll need to queue data
                obj.Session.changeState('NeedOutputData')
            end
        end
        
        function [conn,index] = addTriggerConnection(obj,varargin)
            [conn,index] = obj.Session.doAddTriggerConnection(varargin{:});
        end
        
        function [conn,index] = addClockConnection(obj,varargin)
            [conn,index] = obj.Session.doAddClockConnection(varargin{:});
        end
        
        function removeChannel(obj,index)
            obj.Session.doRemoveChannel(index);
            if numel(obj.Session.Channels) == 0
                obj.Session.changeState('NoChannels')
            elseif obj.Session.Channels.countOutputChannels() > 0 &&...
                    obj.Session.ScansQueued == 0
                % If there's output channels, you'll need to queue data
                obj.Session.changeState('NeedOutputData')
            end
        end
        
        function removeConnection(obj,index)
            obj.Session.doRemoveConnection(index);             
        end        
        
        function errorIfParameterChangeNotOK(~)
            % Parameter changes are OK in this state
        end
        
        function prepare(obj)
            obj.Session.setIsDone(false);
            obj.Session.resetScanCounters();
            obj.Session.doPrepare(true);
            
            % g672448: Only change states if do prepare passed
            obj.Session.changeState('ReadyToStartAndPrepared')
        end
        
        function [data, time, triggerTime] = startForeground(obj) 
            obj.Session.setIsDone(false);
            obj.Session.resetScanCounters();
            obj.Session.doPrepare(false);
            if obj.Session.SyncManager.configurationRequiresExternalTrigger()
                obj.Session.changeState('WaitingForHardwareTrigger');
            else
                obj.Session.changeState('HardwareRunning');
            end            
            try
                [data, time, triggerTime] = obj.Session.doStartForeground();
            catch e
                % If the Prepare succeeds, but the StartForeground fails,
                % then we should move to the prepared state and rethrow the error
                obj.Session.changeState('ReadyToStartAndPrepared')
                rethrow(e)
            end
        end
        
        function startBackground(obj)
            % if you call startBackground without a prepare, implicitly
            % call prepare.
            obj.Session.setIsDone(false);
            obj.Session.resetScanCounters();
            obj.Session.doPrepare(false);
            if obj.Session.SyncManager.configurationRequiresExternalTrigger()
                obj.Session.changeState('WaitingForHardwareTrigger');
            else
                obj.Session.changeState('HardwareRunning');
            end            
            try
                obj.Session.doStartBackground();
            catch e
                % If the Prepare succeeds, but the StartBackground fails,
                % then we should move to the prepared state and rethrow the error
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
            obj.Session.accumulateOutputData(dataToOutput);
        end
        
        function resetCounters(obj)
            obj.Session.doResetCounters();
        end
        
        function [data,triggerTime] = inputSingleScan(obj)
            [data,triggerTime] = obj.Session.doInputSingleScan();
        end
        
        function outputSingleScan(obj,dataToOutput)
            obj.Session.doOutputSingleScan(dataToOutput);
        end
        
        function release(~)
            % Calling release is a no op
        end
                
        function processAcquiredData(obj,~,~,~) %#ok<MANU>
            % Calling processAcquiredData is a no op (allows delayed done
            % event notifications without error)
        end
        
        function processHardwareTrigger(obj,varargin)
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareTrigger','ReadyToStart');
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
        
        function checkForTimeout(obj)
            obj.localizedError('daq:Session:badCommandInThisState','checkForTimeout','ReadyToStart');
        end
    end
    
end

