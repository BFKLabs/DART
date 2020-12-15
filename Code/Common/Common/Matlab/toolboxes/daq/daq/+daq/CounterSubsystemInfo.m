classdef (Hidden) CounterSubsystemInfo < daq.ClockedSubsystemInfo
    %CounterSubsystemInfo Information about an analog subsystem
    %on a device
    %    The specializations of this class are subclassed by
    %adaptors to provide additional information about a
    %particular subsystem implementation.  They may choose to
    %add custom properties and methods.
    
    % Copyright 2009-2012 The MathWorks, Inc.
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        %Resolution an integer representing the bit depth of this
        %subsystem.
        Resolution
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = CounterSubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...                
                CPhysicalChans,...
                rateLimitInfo,...
                resolution)
                %CounterSubsystemInfo Information about a subsystem on a device
                % CounterSubsystemInfo(...,RANGESAVAILABLE,RESOLUTION)
                % See daq.SubsystemInfo and daq.ClockedSubsystemInfo for
                % earlier parameters. A clocked analog
                % subsystem that supports a ranges defined by RANGESAVAILABLE,
                % a vector of daq.Range objects, with resolution of
                % RESOLUTION bits.
            
            obj@daq.ClockedSubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...               
                CPhysicalChans,...
                rateLimitInfo);
            
            if ~isscalar(resolution) ||...
                    ~isnumeric(resolution)
                obj.localizedError('daq:SubsystemInfo:invalidResolution')
            end
            obj.Resolution = resolution;
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function dispText = subsystemDisplay(obj)
            % subsystemDisplay A display function for this class.  This allows each superclass an opportunity to
            % contribute to the subsystem display of a single concrete subsystem object.
            dispText = obj.subsystemDisplay@daq.ClockedSubsystemInfo();
        end
    end
end
