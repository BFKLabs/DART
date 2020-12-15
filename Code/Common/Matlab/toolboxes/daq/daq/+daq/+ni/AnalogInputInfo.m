classdef (Hidden) AnalogInputInfo < daq.AnalogInputInfo
    %AnalogInputInfo Analog input subsystem info for National Instruments devices.
    %
    %    This class represents a analog input subsystem on devices by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2010-2011 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = AnalogInputInfo(infoFromDevice,AIPhysicalChans)
            
            nativeDataType = 'double';
            
            % Call the superclass constructor
            obj@daq.AnalogInputInfo(...
                infoFromDevice.measurementTypesAvailable,...   		% measurement types specified by the cell array of strings
                infoFromDevice.defaultMeasurementType,...
                nativeDataType,...                              % a native data type (MATLAB type string)
                AIPhysicalChans,...                                 % Channel names supported 
                infoFromDevice.rateLimitInfo,...               		%supports rates defined by a daq.internal.ParameterLimit object
                infoFromDevice.rangesAvailableForDifferential,...   %ranges for inputType Differential defined by a vector of daq.Range objects
                infoFromDevice.rangesAvailableForSingleEnded,...    %ranges for inputType SingleEnded defined by a vector of daq.Range objects
                infoFromDevice.rangesAvailableForSingleEndedNonReferenced,...      %ranges for inputType SingleEndedNonReferenced defined by a vector of daq.Range objects
                infoFromDevice.rangesAvailableForPseudoDifferential,...  		    %ranges for inputType PseudoDifferential defined by a vector of daq.Range objects
                infoFromDevice.resolution,...                  %number of bits of resolution
                infoFromDevice.couplingsAvailable,...          %couplings defined by a vector of daq.Coupling objects
                infoFromDevice.sampleType,...                  %sample type defined by a daq.SampleType object
                infoFromDevice.terminalConfigsAvailable,...         %input types defined by a vector of daq.InputType objects.
                infoFromDevice.onDemandOperationsSupported);   %boolean representing On-Demand support
    
        end
    end
    
   
    
    methods(Static)
        function analogInputInfo = createAnalogInputInfo(device,AIPhysicalChans,model)
            
            infoFromDevice = daq.ni.GetAnalogInputInfo(...
                    device,...
                    AIPhysicalChans,...
                    model,...
                    daq.ClockedSubsystemInfo.MinimumSampleRate);
            infoFromDevice.queryDevice();
            
            analogInputInfo = daq.ni.AnalogInputInfo(infoFromDevice,AIPhysicalChans);
        end
    end
end

