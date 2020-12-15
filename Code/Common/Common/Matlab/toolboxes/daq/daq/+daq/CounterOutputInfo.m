classdef (Hidden) CounterOutputInfo < daq.CounterSubsystemInfo
    %CounterOutputInfo Information about an analog input
    %subsystem on a device
    %    This class is subclassed by adaptors to provide
    %additional information about the analog input subsystem of
    %a device.  They may choose to add custom properties and
    %methods.
    
    % Copyright 2009-2011 The MathWorks, Inc.
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
    end
    
    %% -- Protected and private members of the class --

    % Non-public or hidden constructor
    methods(Hidden)
        function obj = CounterOutputInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...                
                COPhysicalChans,...
                rateLimitInfo,...
                resolution,...
                onDemandOperationsSupported)
            
            obj@daq.CounterSubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...
                COPhysicalChans,...
                rateLimitInfo,...
                resolution);
            
            obj.SubsystemTypeInfo = daq.internal.SubsystemType.CounterOutput;
            obj.OnDemandOperationsSupported = onDemandOperationsSupported;
        end
    end
    
    % Property access methods
    methods
    end
    
    % Hidden read only properties
    properties (SetAccess = private,Hidden)
        %OnDemandOperationsSupported An boolean representing if the
        %subsystem supports On-Demand operations like inputSingleScan and
        %outputSingleScan. Devices like DSA series, NI 9237 etc do not
        %support these operations.
        OnDemandOperationsSupported
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function dispText = getDisplayTextImpl(obj)
            % getDisplayTextImpl A display function for this class.  This allows each superclass an opportunity to
            % contribute to the subsystem display.
            dispText = [obj.getLocalizedText('daq:SubsystemInfo:dispCounterOutputHeader') '\n'...
                obj.indentText(obj.subsystemDisplay(),obj.StandardIndent) '\n'];
        end
    end
end

