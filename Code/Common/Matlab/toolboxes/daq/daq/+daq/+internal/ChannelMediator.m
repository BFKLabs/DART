classdef (Hidden) ChannelMediator < daq.internal.BaseClass
    %ChannelMediator Base class for channel mediator objects
    % A channel can register and use a mediator object to define complex
    % interactions between channels, without knowing how many channels are
    % involved.  These mediators must be derived from this base class
    %
    % This is an implementation of the "Mediator" design pattern. Channels
    % are "colleagues" who interact in various ways defined by mediator
    % objects.
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.2 $  $Date: 2010/08/07 07:25:45 $
    
    %% -- Constructor --
    methods
        function obj = ChannelMediator()
            obj.InstanceCount = 0;
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
        % A count of the number of channels that have gotten, but not
        % released this mediator.  When this reaches 0, the mediator
        % instance is deleted.
        InstanceCount
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
