classdef (Hidden) StartTriggerConnection < daq.ni.Connection
    %StartTriggerConnection All settings and operations for an NI start
    %trigger connection
    
    % Copyright 2011 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
     %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = StartTriggerConnection(session,source,destination,type)
            %StartTriggerConnection All settings & operations for an 
            % NI start trigger connection
            %    StartTriggerConnection(SESSION,SOURCE,DESTINATION,TYPE) 
            %    Create a start trigger connection with SESSION, SOURCE,
            %    DESTINATION and TYPE (see daq.Connection)
            
            % Create a trigger connection
            obj@daq.ni.Connection(session,source,destination,type);
            
    
            % Initialize properties to selected defaults
            obj.InitializationInProgress = true;
            
            obj.TriggerType = 'Digital';
            obj.TriggerCondition = 'RisingEdge';
            obj.TriggerConditionInfo = daq.TriggerCondition.RisingEdge;
            
            obj.InitializationInProgress = false;
        end
    end
    
    properties (GetAccess = private,SetAccess = private)
        % Internal property that suppresses set.* functions during
        % initialization
        InitializationInProgress
    end
    
    
    % Setting the TriggerType property is currently not allowed, since we
    % only have one valid option.
    properties (SetAccess = private)
        % The trigger type associated with the connection
        TriggerType
    end
       
    properties 
        % The trigger condition associated with the connection
        TriggerCondition
    end
    
    properties (Hidden)
        % The trigger condition associated with the connection
        TriggerConditionInfo        
        
    end
    
    
    methods( Access = public, Hidden )             
        function connectionTypeFullName = getConnectionFullName(obj)
            % getConnectionFullName A function that returns the full name
            % for the connection
            connectionTypeFullName = obj.getLocalizedText('nidaq:ni:startTrigger');           
        end
    end
    
    
    methods   
        function set.TriggerCondition(obj,newTriggerCondition)
            try
                if obj.InitializationInProgress
                    obj.TriggerCondition = newTriggerCondition;
                    return
                end
                try
                    newTriggerConditionInfo = daq.TriggerCondition.setValue(newTriggerCondition);
                    % Keep the hidden and visible properties in sync
                    obj.TriggerCondition = char(newTriggerConditionInfo);
                    obj.TriggerConditionInfo = newTriggerConditionInfo;
                catch e                   
                    rethrow(e)
                end
            catch e
                % Rethrow any errors as caller, removing the long stack of
                % errors -- capture the full exception in the cause field
                % if FullDebug option is set.
                if daq.internal.getOptions().FullDebug
                    rethrow(e)
                end
                e.throwAsCaller()
            end
        end
    end
end
