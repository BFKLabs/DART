classdef (Hidden) AudioOutputInfo < daq.AudioSubsystemInfo
    %AudioOutputInfo Information about an audio output
    %subsystem on a device
    %    This class is subclassed by adaptors to provide
    %additional information about the audio output subsystem of
    %a device.  They may choose to add custom properties and
    %methods.
    
    % Copyright 2013 The MathWorks, Inc.
    % 
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = AudioOutputInfo(...
                nativeDataType,...
                AOPhysicalChans,...
                rateLimitInfo,...
                rangesAvailableForAudio,...
                resolution,...
                onDemandOperationsSupported)
    
                %AudioOutputInfo Information about an audio output
                %subsystem on a device
                % AudioOutputInfo(...) See daq.SubsystemInfo,
                % daq.ClockedSubsystemInfo, and daq.AudioSubsystemInfo for
                % parameters.
            
            obj@daq.AudioSubsystemInfo(...
                nativeDataType,...               
                AOPhysicalChans,...
                rateLimitInfo,...
                rangesAvailableForAudio,...
                resolution,...
                onDemandOperationsSupported);
    
            obj.SubsystemTypeInfo = daq.internal.SubsystemType.AudioOutput;
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function dispText = getDisplayTextImpl(obj)
            % getDisplayTextImpl A display function for this class.  This allows each superclass an opportunity to
            % contribute to the subsystem display.
            dispText = [obj.getLocalizedText('daq:SubsystemInfo:dispAudioOutputHeader') '\n'...
                obj.indentText(obj.subsystemDisplay(),obj.StandardIndent) '\n'];
        end
    end
   
end
