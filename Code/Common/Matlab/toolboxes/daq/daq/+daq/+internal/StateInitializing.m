classdef (Hidden) StateInitializing < daq.internal.StateSession
    %StateInitializing Initial state of a Session.
    %   StateInitializing provides state specific behaviors for all
    %   operations when the Session is first created.  The daq.Session
    %   object will leave this state before leaving the constructor of the
    %   object.  Not seen under normal conditions.
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
        function obj = StateInitializing(session)
            obj@daq.internal.StateSession(session);
        end
    end
    
    methods
        function [channel,index] = addChannel(obj,varargin) %#ok<STOUT>
            obj.localizedError('daq:Session:badCommandInThisState','addChannel','Initializing');
        end
        
        function [conn,index] = addTriggerConnection(obj,varargin) %#ok<STOUT>
            obj.localizedError('daq:Session:badCommandInThisState','addTriggerConnection','Initializing');
        end
        
        function [conn,index] = addClockConnection(obj,varargin) %#ok<STOUT>
            obj.localizedError('daq:Session:badCommandInThisState','addClockConnection','Initializing');
        end
        
        function removeChannel(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','removeChannel','Initializing');
        end
        
        function removeConnection(obj,~)
             obj.localizedError('daq:Session:badCommandInThisState','removeConnection','Initializing');
        end
        
        function errorIfParameterChangeNotOK(~)
            % Parameter changes are OK in this state
        end
        
        function prepare(obj)
            obj.localizedError('daq:Session:badCommandInThisState','prepare','Initializing');
        end
        
        function [data, time, triggerTime] = startForeground(obj) %#ok<STOUT>
            obj.localizedError('daq:Session:badCommandInThisState','startForeground','Initializing');
        end
        
        function startBackground(obj)
            obj.localizedError('daq:Session:badCommandInThisState','startBackground','Initializing');
        end
        
        function wait(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','wait','Initializing');
        end
        
        function stop(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','stop','Initializing');
        end
        
        function queueOutputData(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','queueOutputData','Initializing');
        end
        
        function resetCounters(obj)
            obj.localizedError('daq:Session:badCommandInThisState','resetCounters','Initializing');
        end
        
        function [data,triggerTime] = inputSingleScan(obj) %#ok<STOUT>
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareTrigger','Initializing');
        end
        
        function outputSingleScan(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','outputSingleScan','Initializing');
        end
        
        function release(obj)
            obj.localizedError('daq:Session:badCommandInThisState','release','Initializing');
        end
        
        function processAcquiredData(obj,~,~,~)
            obj.localizedError('daq:Session:badCommandInThisState','processAcquiredData','Initializing');
        end
        
        function processHardwareTrigger(obj,varargin)
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareTrigger','Initializing');
        end
        
        function processOutputEvent(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','processOutputEvent','Initializing');
        end
        
        function processHardwareStop(obj,~)
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareStop','Initializing');
        end
        
        function result = getIsRunningFlag(~)
            result = false;
        end
        
        function result = getIsLoggingFlag(~)
            result = false;
        end
        
        function result = getIsWaitingForExternalTriggerFlag(~)
            result = true;
        end
        
        function dispSession(obj)
            obj.doDispWhenIdle();
        end
        
        function checkForTimeout(obj)
              obj.localizedError('daq:Session:badCommandInThisState','checkForTimeout','Initializing');
        end
    end
    
end

