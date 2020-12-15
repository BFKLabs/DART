classdef (Hidden) CounterOutputPulseGenerationChannel < daq.CounterOutputChannel
    %CounterOutputPulseGenerationChannel All settings & operations for a
    %counter output voltage channel added to a session.
    %    Vendors can further specialize this to implement
    %    additional behaviors.
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.1 $  $Date: 2010/09/13 15:53:11 $
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterOutputPulseGenerationChannel(session,deviceInfo,id)
            %CounterOutputPulseGenerationChannel All settings & operations for an counter output voltage channel added to a session.
            %    CounterOutputPulseGenerationChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    counter channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)

            % PulseGeneration channels can only use Edges as a range
            obj@daq.CounterOutputChannel(session,deviceInfo,id);
        end
    end
       
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function outputTypeDisplayText = getOutputTypeDisplayHook(obj)
            % getOutputTypeDisplayHook A function that returns the string to
            % display the output type in the display operation
            outputTypeDisplayText = 'PulseGeneration';
        end
        
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
    end
    
end
