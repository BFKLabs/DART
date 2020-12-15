classdef (Hidden) DigitalSubsystemInfo < daq.ClockedSubsystemInfo
    %DigitalSubsystemInfo Information about a digital subsystem
    %on a device.
    %    The specializations of this class are subclassed by
    %adaptors to provide additional information about a
    %particular subsystem implementation. Vendors may choose to
    %add custom properties and methods.
    
    % Copyright 2012 The MathWorks, Inc.
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (Hidden,SetAccess = private)
        %OnDemandOperationsSupported An boolean representing if the
        %subsystem supports On-Demand operations like inputSingleScan and
        %outputSingleScan. 
        OnDemandOperationsSupported
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = DigitalSubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...                
                DIPhysicalChans,...
                DOPhysicalChans,...
                rateLimitInfo,...
                onDemandOperationsSupported)
                %DigitalSubsystemInfo Information about a subsystem on a device
                % DigitalSubsystemInfo(...,RANGESAVAILABLE,RESOLUTION)
                % See daq.SubsystemInfo and daq.ClockedSubsystemInfo for
                % earlier parameters. 
                
                % g1021296: we must vertically concatenate these columns in
                % case they happen to be of different lengths
            DIOPhysicalChans = unique([DIPhysicalChans; DOPhysicalChans]);
                
            obj@daq.ClockedSubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...               
                DIOPhysicalChans,...
                rateLimitInfo);
            
            obj.OnDemandOperationsSupported = onDemandOperationsSupported;
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function dispText = subsystemDisplay(obj)
            % subsystemDisplay A display function for this class.  This
            % allows each superclass an opportunity to contribute to the
            % subsystem display of a single concrete subsystem object.
            dispText = obj.subsystemDisplay@daq.ClockedSubsystemInfo();
        end
    end
end
