classdef (Hidden) AnalogInputInfo < daq.AnalogSubsystemInfo
    %AnalogInputInfo Information about an analog input
    %subsystem on a device
    %    This class is subclassed by adaptors to provide
    %additional information about the analog input subsystem of
    %a device.  They may choose to add custom properties and
    %methods.
    
    % Copyright 2009-2011 The MathWorks, Inc.
    %   
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        %CouplingsAvailable A cell array of strings representing
        %the coupling types supported.
        CouplingsAvailable
        
        %SampleType A string representing the sampling type
        %(scanning vs. simultaneous) that this subsystem uses.
        SampleType
        
        %TerminalConfigsAvailable A string representing the input types
        %(single ended, differential, etc.) that this subsystem uses.
        TerminalConfigsAvailable
               
    end
    
    properties (SetAccess = private, Hidden)
        %InputTypesAvailable A string representing the input types
        %(single ended, differential, etc.) that this subsystem uses. This
        %property is being kept to maintain backward comptability. The new
        %property name is TerminalConfigsAvailable
        InputTypesAvailable
    end
    
    %% -- Protected and private members of the class --

    % Non-public or hidden constructor
    methods(Hidden)
        function obj = AnalogInputInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...
                AIPhysicalChans,...
                rateLimitInfo,...
                rangesAvailableForDifferential,...
                rangesAvailableForSingleEnded,...
                rangesAvailableForSingleEndedNonReferenced,...
                rangesAvailableForPseudoDifferential,...
                resolution,...
                couplingsAvailableInfo,...
                sampleTypeInfo,...
                terminalConfigsAvailableInfo,...,...
                onDemandOperationsSupported)
    
                %AnalogInputInfo Information about a subsystem on a device
                % AnalogInputInfo(...,COUPLINGSAVAILABLEINFO,SAMPLETYPEINFO,INPUTTYPESAVAILABLEINFO)
                % See daq.SubsystemInfo, daq.ClockedSubsystemInfo, and
                % daq.AnalogSubsystemInfo for earlier parameters. A clocked
                % analog input subsystem that supports couplings defined by
                % COUPLINGSAVAILABLEINFO, a vector of daq.Coupling objects,
                % sample type defined by SAMPLETYPEINFO, a daq.SampleType
                % object, and input types defined by
                % INPUTTYPESAVAILABLEINFO, a vector of daq.InputType
                % objects.
            
            obj@daq.AnalogSubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...
                AIPhysicalChans,...
                rateLimitInfo,...
                rangesAvailableForDifferential,...
                rangesAvailableForSingleEnded,...
                rangesAvailableForSingleEndedNonReferenced,...
                rangesAvailableForPseudoDifferential,...
                resolution,...
                onDemandOperationsSupported)
            
            if isempty(couplingsAvailableInfo) ||...
                    ~isa(couplingsAvailableInfo,'daq.Coupling')
                obj.localizedError('daq:SubsystemInfo:invalidCoupling')
            end
            obj.CouplingsAvailableInfo = couplingsAvailableInfo;
            
            if isempty(sampleTypeInfo) ||...
                    ~isa(sampleTypeInfo,'daq.SampleType')
                obj.localizedError('daq:SubsystemInfo:invalidSampleType')
            end
            obj.SampleTypeInfo = sampleTypeInfo;
            
            if isempty(terminalConfigsAvailableInfo) ||...
                    ~isa(terminalConfigsAvailableInfo,'daq.TerminalConfig')
                obj.localizedError('daq:SubsystemInfo:invalidTerminalConfig')
            end
            obj.TerminalConfigsAvailableInfo = terminalConfigsAvailableInfo;
            obj.SubsystemTypeInfo = daq.internal.SubsystemType.AnalogInput;
        end
    end
    
    % Property access methods
    methods
        function result = get.CouplingsAvailable(obj)
            % Return information in the more MATLAB friendly format
            result = obj.CouplingsAvailableInfo.toCellArray();
        end
        
        function result = get.SampleType(obj)
            % Return information in the more MATLAB friendly format
            result = char(obj.SampleTypeInfo);
        end
        
        function result = get.TerminalConfigsAvailable(obj)
            % Return information in the more MATLAB friendly format
            result = obj.TerminalConfigsAvailableInfo.toCellArray();
        end
        
        function result = get.InputTypesAvailable(obj)
            % Return information in the more MATLAB friendly format
            result = obj.TerminalConfigsAvailableInfo.toCellArray();
        end
    end
    
    % Hidden read only properties
    properties (SetAccess = private,Hidden)
        %CouplingsAvailableInfo An array of representations the
        %coupling types supported.
        CouplingsAvailableInfo
        
        %SampleTypeInfo A representation of the sampling type
        %(scanning vs. simultaneous) that this subsystem uses.
        SampleTypeInfo
        
        %TerminalConfigsAvailableInfo An array of representations of the
        %input types that this subsystem supports.
        TerminalConfigsAvailableInfo
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function dispText = getDisplayTextImpl(obj)
            % getDisplayTextImpl A display function for this class.  This allows each superclass an opportunity to
            % contribute to the subsystem display.
            dispText = [obj.getLocalizedText('daq:SubsystemInfo:dispAnalogInputHeader') '\n'...
                obj.indentText(obj.subsystemDisplay(),obj.StandardIndent) '\n'];
        end
    end
end

