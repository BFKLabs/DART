classdef (Hidden) StateNoChannels < daq.internal.StateSession
    %StateNoChannels Session has no channels.
    %   StateNoChannels provides state specific behaviors for all
    %   operations when the Session has no channels.
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
        function obj = StateNoChannels(session)
            obj@daq.internal.StateSession(session);
        end
    end
    
    methods
        function [channel,index] = addChannel(obj,varargin)
            % When there's no channels, it's OK to add them.
            [channel,index] = obj.Session.doAddChannel(varargin{:});
            if obj.Session.RateLimit(2) == 0
                % G687868: Session contains a device that does not support
                % clocked sampling. Only on-demand operations using
                % inputSingleScan and outputSingleScan can be done.
                obj.localizedWarning('daq:Session:onDemandOnlyChannelsAdded');
                obj.Session.changeState('OnDemandOnly')
            elseif obj.Session.Channels.countOutputChannels() > 0
                % If there's output channels, you'll need to queue data
                obj.Session.changeState('NeedOutputData')
            else
                % If there's no output channels, you're OK to go
                obj.Session.changeState('ReadyToStart')
            end
        end
        
        function [conn,index] = addTriggerConnection(obj,varargin) 
           [conn,index] = obj.Session.doAddTriggerConnection(varargin{:});
        end
        
        function [conn,index] = addClockConnection(obj,varargin) 
           [conn,index] = obj.Session.doAddClockConnection(varargin{:});
        end
        
        function removeChannel(obj,~)
            % There's no scenario where removing a channel when there
            % aren't any is OK
            obj.localizedError('daq:Channel:invalidChannel')
        end
        
        function removeConnection(obj,index)
            obj.Session.doRemoveConnection(index);
        end
        
        function errorIfParameterChangeNotOK(~)
            % Parameter changes are OK in this state
        end
        
        function prepare(obj)
            obj.localizedError('daq:Session:noChannels');
        end
        
        function [data, time, triggerTime] = startForeground(obj) %#ok<STOUT>
            obj.localizedError('daq:Session:noChannels');
        end
        
        function startBackground(obj)
            obj.localizedError('daq:Session:noChannels');
        end
        
        function wait(~,~)
            % Calling wait is a no op
        end
        
        function stop(~,~)
            % Calling stop is a no op
        end
        
        function queueOutputData(obj,~)
            obj.localizedError('daq:Session:noChannels');
        end
        
        function resetCounters(obj)
            obj.localizedError('daq:Session:noCounterChannels');
        end
        
        function [data,triggerTime] = inputSingleScan(obj) %#ok<STOUT>
            obj.localizedError('daq:Session:noInputChannels');
        end
        
        function outputSingleScan(obj,~)
            obj.localizedError('daq:Session:noOutputChannels');
        end
        
        function release(~)
            % Calling release is a no op
        end
        
        function processAcquiredData(obj,~,~,~)
            obj.localizedError('daq:Session:badCommandInThisState','processAcquiredData','NoChannels');
        end
        
        function processHardwareTrigger(obj,varargin)
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareTrigger','NoChannels');
        end
        
        function processOutputEvent(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','processOutputEvent','NoChannels');
        end
        
        function processHardwareStop(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareStop','NoChannels');
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
              obj.localizedError('daq:Session:badCommandInThisState','checkForTimeout','NoChannels');
        end
    end
    
end

