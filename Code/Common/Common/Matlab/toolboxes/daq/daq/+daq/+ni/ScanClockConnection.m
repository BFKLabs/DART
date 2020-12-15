classdef (Hidden) ScanClockConnection < daq.ni.Connection
    %ScanClockConnection All settings and operations for an NI scan clock
    %connection
    
    % Copyright 2011 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = ScanClockConnection(session,source,destination,type)
            %StartTriggerConnection All settings & operations for an 
            % NI scan clock connection
            %    ScanClockConnection(SESSION,SOURCE,DESTINATION,TYPE) 
            %    Create a scan clock connection with SESSION, SOURCE,
            %    DESTINATION and TYPE (see daq.Connection)
            
            obj@daq.ni.Connection(session,source,destination,type);
        end
    end
   
    methods ( Access = public, Hidden )       
        function connectionTypeFullName = getConnectionFullName(obj)
            % getConnectionFullName A function that returns the full name
            % for the connection
            connectionTypeFullName = obj.getLocalizedText('nidaq:ni:scanClock');            
        end
        
    end
end
