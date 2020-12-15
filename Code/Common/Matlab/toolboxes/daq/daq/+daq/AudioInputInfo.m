classdef (Hidden) AudioInputInfo < daq.AudioSubsystemInfo
    %AudioInputInfo Information about an audio input
    %subsystem on a device
    %    This class is subclassed by adaptors to provide
    %additional information about the audio input subsystem of
    %a device.  They may choose to add custom properties and
    %methods.
    
    % Copyright 2013 The MathWorks, Inc.
    %   
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        % SamplingType: all audio channels are Simultaneous
    end
    
    properties (SetAccess = private, Hidden)
    end
    
    %% -- Protected and private members of the class --

    % Non-public or hidden constructor
    methods(Hidden)
        function obj = AudioInputInfo(...
                nativeDataType,...
                AIPhysicalChans,...
                rateLimitInfo,...
                rangesAvailableForAudio,...
                resolution,...
                onDemandOperationsSupported)
    
                %AudioInputInfo Information about a subsystem on a device
                % AudioInputInfo(...,COUPLINGSAVAILABLEINFO,SAMPLETYPEINFO,INPUTTYPESAVAILABLEINFO)
                % See daq.SubsystemInfo, daq.ClockedSubsystemInfo, and
                % daq.AudioSubsystemInfo for earlier parameters. An 
                % audio input subsystem that supports couplings defined by
                % COUPLINGSAVAILABLEINFO, a vector of daq.Coupling objects,
                % sample type defined by SAMPLETYPEINFO, a daq.SampleType
                % object, and input types defined by
                % INPUTTYPESAVAILABLEINFO, a vector of daq.InputType
                % objects.
            
            obj@daq.AudioSubsystemInfo(...
                nativeDataType,...
                AIPhysicalChans,...
                rateLimitInfo,...
                rangesAvailableForAudio,...
                resolution,...
                onDemandOperationsSupported)
            
            obj.SubsystemTypeInfo = daq.internal.SubsystemType.AudioInput;
        end
    end
    
    % Property access methods
    methods
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function dispText = getDisplayTextImpl(obj)
            % getDisplayTextImpl A display function for this class.  This allows each superclass an opportunity to
            % contribute to the subsystem display.
            dispText = [obj.getLocalizedText('daq:SubsystemInfo:dispAudioInputHeader') '\n'...
                obj.indentText(obj.subsystemDisplay(),obj.StandardIndent) '\n'];
        end
    end
end

