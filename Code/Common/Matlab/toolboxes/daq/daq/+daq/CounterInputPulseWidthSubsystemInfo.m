classdef (Hidden) CounterInputPulseWidthSubsystemInfo < handle
    %CounterInputPulseWidthSubsystemInfo Information about an counter pulse 
    %width subsystem on a device
    
    % Copyright 2011 The MathWorks, Inc.
    %   
    
    %% -- Public methods, properties, and events --
    % Read only properties
	% Add frequency channel properties that require special defaults during creation
    properties (Hidden,SetAccess = private)
        DefaultMinMaxExpectedPulseWidth;
        
        %OnDemandOperationsSupported An boolean representing if the
        %subsystem supports On-Demand operations like inputSingleScan and
        %outputSingleScan. Devices like DSA series, NI 9237 etc do not
        %support these operations.
        OnDemandOperationsSupportedPulseWidth        
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
	methods(Hidden)
		function obj = CounterInputPulseWidthSubsystemInfo( ...
                defaultMinMaxExpectedPulseWidth,...
                onDemandOperationsSupported)
            
            obj.DefaultMinMaxExpectedPulseWidth = defaultMinMaxExpectedPulseWidth;
            obj.OnDemandOperationsSupportedPulseWidth = onDemandOperationsSupported;
		end
    end    

end