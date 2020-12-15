classdef (Hidden) AnalogSubsystemInfo < daq.ClockedSubsystemInfo
    %AnalogSubsystemInfo Information about an analog subsystem
    %on a device
    %    The specializations of this class are subclassed by
    %adaptors to provide additional information about a
    %particular subsystem implementation.  They may choose to
    %add custom properties and methods.
    
    % Copyright 2009-2011 The MathWorks, Inc.
    %   
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        %RangesAvailable An array of daq.Range objects representing the 
        %super set of all analog ranges supported by various InputTypes
        RangesAvailable
        
        %Resolution an integer representing the bit depth of this
        %subsystem.
        Resolution        
    end
    
    properties (SetAccess = private, Hidden)
        %OnDemandOperationsSupported An boolean representing if the
        %subsystem supports On-Demand operations like inputSingleScan and
        %outputSingleScan. Devices like DSA series, NI 9237 etc do not 
        %support these operations.
        OnDemandOperationsSupported    
    end
    
    properties (Hidden , SetAccess = private)    
        %RangesAvailableForDifferential An array of daq.Range objects
        %representing the analog ranges supported for InputType Differential.
        RangesAvailableForDifferential;
        
        %RangesAvailableForSingleEnded An array of daq.Range objects
        %representing the analog ranges supported for InputType SingleEnded.
        RangesAvailableForSingleEnded;
        
        %RangesAvailableForSingleEndedNonReferenced An array of daq.Range
        %objects representing the analog ranges supported for InputType
        %SingleEndedNonReferenced.
        RangesAvailableForSingleEndedNonReferenced;
        
        %RangesAvailableForPseudoDifferential An array of daq.Range objects
        %representing the analog ranges supported for InputType PseudoDifferential.
        RangesAvailableForPseudoDifferential;
        
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = AnalogSubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...
                APhysicalChans,...
                rateLimitInfo,...
                rangesAvailableForDifferential,...
                rangesAvailableForSingleEnded,...
                rangesAvailableForSingleEndedNonReferenced,...
                rangesAvailableForPseudoDifferential,...
                resolution,...
                onDemandOperationsSupported)
                %AnalogSubsystemInfo Information about a subsystem on a device
                % AnalogSubsystemInfo(...,RANGESAVAILABLE,RESOLUTION)
                % See daq.SubsystemInfo and daq.ClockedSubsystemInfo for
                % earlier parameters. A clocked analog
                % subsystem that supports a ranges defined by RANGESAVAILABLE,
                % a vector of daq.Range objects, with resolution of
                % RESOLUTION bits.
            
            obj@daq.ClockedSubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...
                APhysicalChans,...
                rateLimitInfo);
            
            if ~isa(rangesAvailableForDifferential,'daq.Range')
                obj.localizedError('daq:SubsystemInfo:invalidRange')
            end
            if ~isa(rangesAvailableForSingleEnded,'daq.Range')
                obj.localizedError('daq:SubsystemInfo:invalidRange')
            end
            if ~isa(rangesAvailableForSingleEndedNonReferenced,'daq.Range')
                obj.localizedError('daq:SubsystemInfo:invalidRange')
            end
            if ~isa(rangesAvailableForPseudoDifferential,'daq.Range')
                obj.localizedError('daq:SubsystemInfo:invalidRange')
            end
            
            obj.RangesAvailableForDifferential = rangesAvailableForDifferential;
            obj.RangesAvailableForSingleEnded = rangesAvailableForSingleEnded;
            obj.RangesAvailableForSingleEndedNonReferenced = rangesAvailableForSingleEndedNonReferenced;
            obj.RangesAvailableForPseudoDifferential = rangesAvailableForPseudoDifferential;
            
            obj.RangesAvailable = obj.findLargestSupportedRange();
            
            % We set resolution as 'Unknown' when we are unable to find it
            % from the device.
            if (~isscalar(resolution) ||...
                    ~isnumeric(resolution) ) && ~strcmp('Unknown',resolution)
                obj.localizedError('daq:SubsystemInfo:invalidResolution')
            end
            
            obj.Resolution                  = resolution;            
            obj.OnDemandOperationsSupported = onDemandOperationsSupported;
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function dispText = subsystemDisplay(obj)
            % subsystemDisplay A display function for this class.  This allows each superclass an opportunity to
            % contribute to the subsystem display of a single concrete subsystem object.
                                       
            if numel( obj.RangesAvailable) == 1
                dispText = obj.getLocalizedText('daq:SubsystemInfo:dispRangesSingular',char( obj.RangesAvailable));
            elseif numel( obj.RangesAvailable) < 3
                dispText = obj.getLocalizedText('daq:SubsystemInfo:dispRangesPlural',char( obj.RangesAvailable));
            else
                dispText = obj.getLocalizedText('daq:SubsystemInfo:dispRangesMany',num2str(numel( obj.RangesAvailable)));
            end
            dispText = [dispText '\n' obj.subsystemDisplay@daq.ClockedSubsystemInfo()];
        end
    end
    
    methods (Access = private)
        function dispRange = findLargestSupportedRange(obj)
            combinedRanges = {obj.RangesAvailableForDifferential,...
                obj.RangesAvailableForSingleEnded,...
                obj.RangesAvailableForSingleEndedNonReferenced,...
                obj.RangesAvailableForPseudoDifferential};
			
			if(all(cellfun(@isempty,combinedRanges)))
				obj.localizedError('daq:SubsystemInfo:invalidRange')
			end
			
            [ ~,largestIndex ] = max(cellfun(@numel,combinedRanges));
            dispRange = combinedRanges{largestIndex};
        end
    end
end
