classdef (Hidden) CounterInputFrequencySubsystemInfo < handle
    %CounterInputFrequencySubsystemInfo Information about an counter frequency 
    %subsystem on a device
    
    % Copyright 2011 The MathWorks, Inc.
    %   
    
    %% -- Public methods, properties, and events --
    % Read only properties
	% Add frequency channel properties that require special defaults during creation
    properties (Hidden,SetAccess = private)
        DefaultMinMaxExpectedFrequency;
        
        %OnDemandOperationsSupported An boolean representing if the
        %subsystem supports On-Demand operations like inputSingleScan and
        %outputSingleScan. Devices like DSA series, NI 9237 etc do not
        %support these operations.
        OnDemandOperationsSupportedFrequency
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
		function obj = CounterInputFrequencySubsystemInfo(...
                defaultMinMaxExpectedFrequency,...
                onDemandOperationsSupported)
            
            obj.DefaultMinMaxExpectedFrequency = defaultMinMaxExpectedFrequency;
            obj.OnDemandOperationsSupportedFrequency = onDemandOperationsSupported;
		end    
    end    
end