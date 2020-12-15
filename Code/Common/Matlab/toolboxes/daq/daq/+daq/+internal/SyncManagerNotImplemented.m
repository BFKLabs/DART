classdef SyncManagerNotImplemented < daq.SyncManager
    %SyncNotImplemented An implementation of daq.SyncManager that returns errors
    %    SyncManagerNotImplemented is the default class that provides reasonable
    %    error messages when Sync operations are called on adaptors that do
    %    not support them.
    
    % Copyright 2011 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
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
        function obj = SyncManagerNotImplemented(session)
            obj@daq.SyncManager(session);
        end
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

    % Protected properties for use by a subclass
    properties(GetAccess=protected,SetAccess=protected)
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
    methods (Access = protected)
        function connectionBeingAddedImpl(~,~) 
        end
        
    end
    
    methods (Access = public,Hidden)
        function result = configurationRequiresExternalTriggerImpl(~)
            result = 0;
        end
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
    end
    
    % Private methods
    methods (Access = private)
    end
end
