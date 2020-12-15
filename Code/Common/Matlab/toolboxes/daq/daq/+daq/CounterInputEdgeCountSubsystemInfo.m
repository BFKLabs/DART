classdef (Hidden) CounterInputEdgeCountSubsystemInfo < handle
    %CounterEdgeCountSubsystemInfo Information about an counter edge count 
    %subsystem on a device
    
    % Copyright 2011 The MathWorks, Inc.
    %   
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (Hidden,SetAccess = private)
    
        % ActiveEdgesAvailable A cell specifying the edges supported by the
        % EdgeCount mode in counter subsystem.
        ActiveEdgesAvailable
  
        % DefaultActiveEdge A string specifying the default active edge
        % that will be used when creating EdgeCount channel.
        DefaultActiveEdge   
        
        %OnDemandOperationsSupported An boolean representing if the
        %subsystem supports On-Demand operations like inputSingleScan and
        %outputSingleScan. Devices like DSA series, NI 9237 etc do not
        %support these operations.
        OnDemandOperationsSupportedEdgeCount
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = CounterInputEdgeCountSubsystemInfo(...
                activeEdgesAvailable, ...
                defaultActiveEdge,...
                onDemandOperationsSupported)
            
            obj.ActiveEdgesAvailable = activeEdgesAvailable;
            
            obj.DefaultActiveEdge = defaultActiveEdge;
            
            obj.OnDemandOperationsSupportedEdgeCount = onDemandOperationsSupported;
                       
        end
    end    

end