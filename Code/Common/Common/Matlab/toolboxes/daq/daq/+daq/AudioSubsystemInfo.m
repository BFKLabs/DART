classdef (Hidden) AudioSubsystemInfo < daq.ClockedSubsystemInfo
    %AudioSubsystemInfo Information about an audio subsystem
    %on a device
    
    % Copyright 2013 The MathWorks, Inc.
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
        %subsystem supports On-Demand operations like inputSingleScan and
        %outputSingleScan        
        OnDemandOperationsSupported
    end
    
    properties (SetAccess = private, Hidden)    
        %RangesAvailableForAudio An array of daq.Range objects
        %representing the ranges supported for audio data
        RangesAvailableForAudio;
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = AudioSubsystemInfo(...
                nativeDataType,...
                APhysicalChans,...
                rateLimitInfo,...
                rangesAvailableForAudio,...
                resolution,...
                onDemandOperationsSupported)

                %AnalogSubsystemInfo Information about a subsystem on a device
                % AnalogSubsystemInfo(...,RANGESAVAILABLE,RESOLUTION)
                % See daq.SubsystemInfo and daq.ClockedSubsystemInfo for
                % earlier parameters. A clocked analog
                % subsystem that supports a ranges defined by RANGESAVAILABLE,
                % a vector of daq.Range objects, with resolution of
                % RESOLUTION bits.
                
            measurementTypesAvailable = {'Audio'};
            defaultMeasurementType = 'Audio';
            
            obj@daq.ClockedSubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...
                APhysicalChans,...
                rateLimitInfo);
            
            if ~isa(rangesAvailableForAudio, 'daq.Range')
                obj.localizedError('daq:SubsystemInfo:invalidRange')
            end
            
            obj.RangesAvailableForAudio = rangesAvailableForAudio;

            obj.RangesAvailable = obj.findLargestSupportedRange();
            
            % We set resolution as 'Unknown' when we are unable to find it
            % from the device.
            if (~isscalar(resolution) ||...
                    ~isnumeric(resolution) ) && ~strcmp('Unknown',resolution)
                obj.localizedError('daq:SubsystemInfo:invalidResolution')
            end
            
            obj.Resolution = resolution;   
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
            audioRanges = {obj.RangesAvailableForAudio};
			
			if(all(cellfun(@isempty, audioRanges)))
				obj.localizedError('daq:SubsystemInfo:invalidRange')
			end
			
            [ ~,largestIndex ] = max(cellfun(@numel, audioRanges));
            dispRange = audioRanges{largestIndex};
        end
    end
end
