classdef (Hidden) CounterChannel < daq.Channel
    %CounterChannel All settings & operations for an analog channel added to a session.
    %    This class is specialized for each class of analog channel that is
    %    possible.  Vendors further specialize those to implement
    %    additional behaviors.
    
    % Copyright 2010-2011 The MathWorks, Inc.
    % $Revision: 1.1.6.3 $  $Date: 2011/01/28 18:48:21 $
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    
    methods(Hidden)
        function obj = CounterChannel(subsystemType,session,deviceInfo,id)
            %CounterChannel All settings & operations for an analog channel added to a session.
            %    CounterChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            obj@daq.Channel(subsystemType,session,deviceInfo,id);
        end
    end
    
    % Protected methods this class is required to implement
    methods (Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if  ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
    end
end
