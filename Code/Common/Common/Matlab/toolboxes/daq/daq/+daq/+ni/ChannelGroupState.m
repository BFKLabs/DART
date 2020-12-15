classdef (Hidden) ChannelGroupState < daq.internal.BaseClass
    %ChannelGroupState States associated with a ChannelGroup
    %    ChannelGroupState Put your detailed info here
    
    % Copyright 2010-2011 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = ChannelGroupState(channelGroup)
            obj.ChannelGroup = channelGroup;
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
        
    % Methods
    methods
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
    end
    
    % Property accessor methods
    methods
    end
    
    % Hidden properties
    properties(Hidden)
    end
    
    % Hidden read only properties
    properties(Hidden,SetAccess = private)
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
    end

    % Hidden public sealed methods, which are typically used as friend methods
    methods (Sealed, Hidden)
    end
        
    % Hidden static methods, which are typically used as friend methods
    methods(Hidden,Static)
    end
   
    % Protected read only properties for use by a subclass
    properties(GetAccess=protected,SetAccess=private)
        ChannelGroup
    end
   
    % Protected constants for use by a subclass
    properties(GetAccess=protected,Constant)
    end
    
    methods (Abstract)
        taskHandle = getUnreservedTaskHandle(obj)
        taskHandle = getCommittedTaskHandle(obj)
        configureForMultipleScans(obj)
        updateNumberOfScans(obj)
        configureForSingleScan(obj)
        configureForNextStart(obj)
        setup(obj)
        start(obj)
        stop(obj)
        writeData(obj,dataToOutput)
        flush(obj)
        unreserve(obj)
        clearTask(obj)
        result = getIsRunning(obj)
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
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

    % Internal constants
    properties(Constant, GetAccess = private)
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end
    
    % Private methods
    methods (Access = private)
    end
end
