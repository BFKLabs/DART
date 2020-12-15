classdef (Hidden) DigitalIOInfo < daq.DigitalSubsystemInfo 
    %DigitalIOInfo Information about a digital input/output
    %subsystem on a device.
    %    This class is subclassed by adaptors to provide
    %additional information about the digital subsystem of
    %a device. Vendors may choose to add custom properties and
    %methods.
    
    % Copyright 2012 The MathWorks, Inc.
    %   
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (Hidden, SetAccess = private)
        DIPhysicalChans
        DOPhysicalChans
    end
    
    %% -- Protected and private members of the class --
    
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = DigitalIOInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...                
                DIPhysicalChans,...
                DOPhysicalChans,...
                rateLimitInfo,...
                onDemandOperationsSupported)
            
            %DigitalSubsystemInfo Information about a subsystem on a device
            % DigitalSubsystemInfo(...,RANGESAVAILABLE)
            % See daq.SubsystemInfo and daq.ClockedSubsystemInfo for
            % earlier parameters. A clocked analog
            % subsystem that supports a ranges defined by RANGESAVAILABLE,
            % a vector of daq.Range objects.
            obj@daq.DigitalSubsystemInfo( ...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...               
                DIPhysicalChans,...
                DOPhysicalChans,...
                rateLimitInfo,...
                onDemandOperationsSupported);
            
            obj.SubsystemTypeInfo = daq.internal.SubsystemType.DigitalIO;
            obj.DIPhysicalChans = DIPhysicalChans;
            obj.DOPhysicalChans = DOPhysicalChans;
        end
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function dispText = getDisplayTextImpl(obj)
            % getDisplayTextImpl A display function for this class.  This
            % allows each superclass an opportunity to contribute to the
            % subsystem display.
            dispText = [obj.getLocalizedText('daq:SubsystemInfo:dispDigitalHeader') '\n'...
                obj.indentText(obj.subsystemDisplay(),obj.StandardIndent) '\n'];
        end
    end
end

