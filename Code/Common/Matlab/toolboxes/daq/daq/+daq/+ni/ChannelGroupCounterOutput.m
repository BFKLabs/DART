classdef (Hidden) ChannelGroupCounterOutput < daq.ni.ChannelGroup
    %ChannelGroup Represents a NI-DAQmx task used for counter output
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = ChannelGroupCounterOutput(session,name)
            % Get the device name from the group name
            idx = strfind(name,'/');
            deviceID = name(idx(1)+1:idx(2)-1);
            obj@daq.ni.ChannelGroup(session,name,deviceID);
            
            obj.CounterTimer = [];
            
            obj.IsSingleScanTiming = false;
        end
    end
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
    end
    
    % Read only properties
    properties (SetAccess = private)
    end
    
    % Read only properties that can be altered by a subclass
    properties (SetAccess = protected)
    end
    
    % Constants
    properties(Constant, GetAccess = private)
    end
    
    % Sealed methods
    methods(Sealed)
    end
    
    % Events
    events
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
    end
    
    % Destructor
    methods
        function delete(obj)
            obj.deleteTimer();
        end
    end
    
    % Property accessor methods
    methods
    end
    
    % Hidden properties
    properties(Hidden)
    end
    
    % Hidden read only properties
    properties(Hidden,SetAccess = private)
        CounterTimer;
        
        IsSingleScanTiming;
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function doConfigureForSingleScan(obj)
            try
                if obj.IsSingleScanTiming == false
                    obj.clearTask();
                    obj.doCreateTask();
                    obj.commitTask();
                    obj.updateChannelMap();
                    obj.IsSingleScanTiming = true;
                end
            catch e
                obj.clearTask();
                obj.doCreateTask();
                obj.updateChannelMap();
                obj.IsSingleScanTiming = false;
                error = obj.Session.processNIDAQmxDriverError(obj.ChannelIOIndexMap, ...
                    e.identifier, ...
                    e.message);
                throw(error);
            end
        end
        
        function doConfigureForMultipleScans(obj)
            try
                % CO subsystems are currently not synchronized. Warn if
                % clock or trigger connections were added for CO device.
                obj.warnIfConnectionsAdded();
                % G673218: Session cannot startForeground if the task is
                % already running.
                obj.stopTask();
                obj.doUpdateNumberOfScans();
                obj.IsSingleScanTiming = false;
            catch e
                error = obj.Session.processNIDAQmxDriverError(obj.ChannelIOIndexMap, ...
                    e.identifier, ...
                    e.message);
                throw(error);
            end
        end
        
        function warnIfConnectionsAdded(obj)
            %Check for Trigger and clock connections
            if ~isempty(obj.Session.Connections)
                obj.localizedWarning('nidaq:ni:CONotSynchronized');
            end
        end
        
        function doUpdateNumberOfScans(obj)
            obj.doConfigureReferenceClock();
            status = daq.ni.NIDAQmx.DAQmxCfgImplicitTiming(...
                obj.TaskHandle,...
                daq.ni.NIDAQmx.DAQmx_Val_ContSamps,...
                uint64(obj.Session.NumberOfScans));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function doFlush(obj) %#ok<MANU>
            % do nothing
        end
        
        function doSetup(obj)
            obj.stopTask();
            if obj.Session.NumberOfScans == 0 || obj.Session.IsContinuous == true
                obj.deleteTimer();
            else
                if isempty(obj.CounterTimer)
                    % If finite mode, use a timer to simulate a done event
                    obj.CounterTimer = timer('TimerFcn', @noOp, ...
                        'StopFcn', {@handleCODoneEvent, obj}, ...
                        'ExecutionMode','singleShot', ...
                        'BusyMode', 'queue');
                end
                
                % G878159: Eliminate sub-millisecond warning on StartDelay;
                % round duration to nearest millisecond value.
                %
				% G877762: The counter timer is used to stop the counter
				% output pulse generation. A 0.2 second delay is used to
				% ensure the pulse generation is not stopped prematurely.
                obj.CounterTimer.StartDelay = (ceil(obj.Session.DurationInSeconds*1000))/1000 + 0.2;
            end
            
            function handleCODoneEvent(~, ~, counterObj)
                counterObj.handleStop([]);
            end
            
            %Timer doesn't work if the TimerFcn isn't defined
            function noOp(~, ~, ~)
            end
        end
        
        function doStart(obj)
            status = daq.ni.NIDAQmx.DAQmxStartTask(obj.TaskHandle);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            if obj.Session.NumberOfScans ~= 0 && ~isempty(obj.CounterTimer)
                start(obj.CounterTimer);
            end
        end
        
        function doStop(obj)
            persistent insideCritSection; if isempty(insideCritSection),insideCritSection=false;end;
            if ~insideCritSection
                insideCritSection = true; %#ok<NASGU>
                obj.stopTask();
                
                if isempty(obj.CounterTimer)
                    obj.handleStop([]);
                else
                    stop(obj.CounterTimer);
                end
                insideCritSection = false;
            end
        end
    end
    
    methods
        %openStream Open and AsyncIO channel
        function openStream(obj, taskHandle, numberOfScans, bufferingBlockSize, numChannels, isContinuous, externalTriggerTimeout) %#ok<INUSD,MANU>
        end
        
        %flushStream flush and AsyncIO channel
        function flushStream(obj) %#ok<MANU>
        end
        
        %closeStream Close an AsyncIO channel
        function closeStream(obj) %#ok<MANU>
        end
        
        %startTask Send start command to device plugin
        function startTask(obj) %#ok<MANU>
        end
    end
    
    % Hidden public sealed methods, which are typically used as friend methods
    methods (Sealed, Hidden)
    end
    
    % Hidden static methods, which are typically used as friend methods
    methods(Hidden,Static)
    end
    
    % Protected read only properties for use by a subclass
    properties(GetAccess=protected,SetAccess=private)
    end
    
    % Protected constants for use by a subclass
    properties(GetAccess=protected,Constant)
    end
    
    % Protected methods requiring implementation by a subclass
    methods (Abstract,Access = protected)
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Hidden)
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
    end
    
    % Protected static methods for use by a subclass
    methods (Sealed,Static,Access=protected)
    end
    
    % Private properties
    properties (GetAccess = private,SetAccess = private)
    end
    
    % Private methods
    methods (Access = private)
        function deleteTimer(obj)
            % Delete the timer object, if it exists
            if ~isempty(obj.CounterTimer)
                try
                    stop(obj.CounterTimer)
                catch %#ok<CTCH>
                    % Ignore failures
                end
                try
                    delete(obj.CounterTimer)
                catch %#ok<CTCH>
                    % Ignore failures
                end
                try
                    obj.CounterTimer = [];
                catch %#ok<CTCH>
                    % Ignore failures
                end
            end
        end
    end
    
    % Internal constants
    properties(Constant, GetAccess = private)
    end
    
    % Superclass methods this class implements
    methods (Hidden)
        function updateChannelMap(obj)
            updateChannelMapBase(obj,daq.internal.SubsystemType.CounterOutput);
        end
    end
end
