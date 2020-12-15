classdef (Hidden) SessionFactory < daq.internal.BaseClass & daq.internal.UserDeleteDisabled
    %SessionFactory Base class for creating session objects
    % Session factories are implemented by adaptors to generate Session
    % objects appropriate to the vendor
    %
    %    This undocumented class may be removed in a future release.
   
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.2 $  $Date: 2010/08/07 07:25:50 $

    %% -- Public methods, properties, and events --
    
    % Sealed methods
    methods(Sealed)
        function session = createSession(obj,varargin)
            session = obj.createSessionHook(obj.Vendor,varargin{:});
        end
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = SessionFactory(vendor,className)
            %SessionFactory default session factory
            % SessionFactory(className) creates a factory that creates a
            % session using the class name passed into the constructor.
            % Vendors may choose to specialize this to provide more complex
            % behaviors and handlers associated with session creation.
            if isempty(className) || ~ischar(className)
                obj.localizedError('daq:general:invalidClassName')
            end
            obj.Vendor = vendor;
            obj.ClassName = className;
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        %Subclasses may override to return a session for
        %their adaptor, appropriate to the parameters passed.
        function session = createSessionHook(obj,varargin) 
            % Default instantiates the session class, passing in all arguments.
            session = feval(str2func(obj.ClassName),varargin{:});
        end
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
    
    % Private properties
    properties(GetAccess = private,SetAccess = private)
        Vendor
        ClassName
    end
    
end

