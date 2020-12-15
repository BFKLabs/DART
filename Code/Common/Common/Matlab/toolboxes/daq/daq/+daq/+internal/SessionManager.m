classdef (Hidden) SessionManager < daq.internal.BaseClass & daq.internal.UserDeleteDisabled
    %SessionManager Singleton for creating sessions
    % Session manager maintains the list of Session factories, and
    % dispatches session creation to the factory objects appropriate to the
    % vendor
    %
    %    This undocumented class may be removed in a future release.
   
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.2 $  $Date: 2010/08/07 07:25:51 $

    %% -- Public methods, properties, and events --
        
    % Methods
    methods
        function registerSessionFactory(obj,key,factoryObject)
            % registerSessionFactory register a factory, and the key to use
            % to retrieve it.  Typically, the key corresponds to the vendor
            % name, but a vendor may choose to register several factories,
            % if needed.
            if isempty(key) || ~ischar(key) || ~isa(factoryObject,'daq.internal.SessionFactory')
                obj.localizedError('daq:general:invalidSessionFactory')
            end
            if obj.SessionFactoryMap.isKey(key)
                obj.localizedError('daq:general:factoryAlreadyRegistered',key)
            end
                
            obj.SessionFactoryMap(key) = factoryObject;
        end
        
        function sessionFactory = getSessionFactory(obj,key)
            % getSessionFactory retrieve a session factory using a key,
            % typically the vendor name
            try
                sessionFactory = obj.SessionFactoryMap(key);
            catch %#ok<CTCH>
                obj.localizedError('daq:general:unknownVendor',key);
            end
        end
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Access=private)
        function obj = SessionManager()
            obj.SessionFactoryMap = containers.Map();
        end
    end
    
    % Hidden static methods, which are typically used as friend methods
    methods(Static)
        function value = getInstance()
            persistent Instance;
            
            if isempty(Instance) || ~isvalid(Instance)
                Instance = daq.internal.SessionManager();
            end
            value = Instance;
        end
    end
    
    % Protected methods requiring implementation by a subclass
    methods(Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end

    % Private properties
    properties(GetAccess = private, SetAccess = private)
        SessionFactoryMap
    end
    
end

