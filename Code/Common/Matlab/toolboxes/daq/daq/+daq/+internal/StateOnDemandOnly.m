classdef (Hidden) StateOnDemandOnly < daq.internal.StateSession
    %StateOnDemandOnly Session is limited to on demand only operations.
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2011 The MathWorks, Inc.
    
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
        function obj = StateOnDemandOnly(session)
            obj@daq.internal.StateSession(session);
        end
    end
    

    methods
        function [channel,index] = addChannel(obj,varargin)
            [channel,index] = obj.Session.doAddChannel(varargin{:});
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
            elseif obj.Session.RateLimit(2) == 0
                % Stay in OnDemandOnly state
                return
            elseif obj.Session.Channels.countOutputChannels() > 0 &&...
                    obj.Session.ScansQueued == 0
                % If there's output channels, you'll need to queue data
                obj.Session.changeState('NeedOutputData')
            else
                obj.Session.changeState('ReadyToStart')
            end
        end
        
        function removeConnection(obj,index) 
            obj.Session.doRemoveConnection(index);
        end
        
        function errorIfParameterChangeNotOK(~)
            % Parameter changes are OK in this state
        end
        
        function prepare(obj) %#ok<MANU>
            % Calling prepare is a no op
        end
        
        function [data, time, triggerTime] = startForeground(obj) %#ok<STOUT>
            obj.Session.localizedError('daq:Session:clockedOperationsDisabled');
        end
        
        function startBackground(obj)
            obj.Session.localizedError('daq:Session:clockedOperationsDisabled');
        end
        
        function wait(~,~)
            % Calling wait is a no op
        end
        
        function stop(~,~)
            % Calling stop is a no op
        end
        
        function queueOutputData(obj,~)
            obj.Session.localizedError('daq:Session:queueOutputDataDisabled');
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
            obj.localizedError('daq:Session:badCommandInThisState','processHardwareTrigger','OnDemandOnly');
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
	    operationalLengthText = obj.getLocalizedText('daq:Session:dispOperationOnDemandOnly');
                fprintf(obj.indentText(operationalLengthText,...
         	daq.internal.BaseClass.StandardIndent));
 		fprintf('\n');
        end
        
        function checkForTimeout(obj)
            obj.localizedError('daq:Session:badCommandInThisState','checkForTimeout','OnDemandOnly');
        end
    end
    
end

