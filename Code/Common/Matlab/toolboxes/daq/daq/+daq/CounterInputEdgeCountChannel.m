classdef (Hidden) CounterInputEdgeCountChannel < daq.CounterInputChannel
    %CounterInputEdgeCountChannel All settings & operations for a counter
    %input EdgeCount channel added to a session.
    %    Vendors can further specialize this to implement
    %    additional behaviors.
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.2 $  $Date: 2010/09/13 15:53:04 $
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputEdgeCountChannel(session,deviceInfo,id)
            %CounterInputEdgeCountChannel All settings & operations for a
            %counter input EdgeCount channel added to a session.
            %    CounterInputEdgeCountChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)

            % EdgeCount channels can only use Edges as a range
            obj@daq.CounterInputChannel(session,deviceInfo,id);
        end
    end
       
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function inputTypeDisplayText = getInputTypeDisplayHook(obj)
            % getInputTypeDisplayHook A function that returns the string to
            % display the input type in the display operation
            inputTypeDisplayText = 'EdgeCount';
        end
        
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
    end
    
end
