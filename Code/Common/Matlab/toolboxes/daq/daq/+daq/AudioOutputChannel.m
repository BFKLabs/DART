classdef (Hidden) AudioOutputChannel < daq.AudioChannel
    %AudioOutputChannel All settings & operations for an audio output channel added to a session.
    %    This class is specialized for each possible class of audio output channel. 
    %    Vendors further specialize those to implement additional behaviors.
    
    % Copyright 2013 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
   
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AudioOutputChannel(session, deviceInfo, id)
            %AudioOutputChannel All settings & operations for an audio output channel added to a session.
            %    AudioOutputChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create an
            %    audio channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Get the ranges from the device subsystem that are of the
            % correct units.
            subsystem = deviceInfo.getSubsystem(daq.internal.SubsystemType.AudioOutput);
            if isempty(subsystem)
                % Haven't instantiated the base class yet -- call
                % messageID direct
                error(message('daq:Channel:deviceDoesNotSupportChannelType'))
            end
			
			% The supported ranges depend on data type, not measurement type.
			% Data types: double, int16, uint8 and maybe single.
			% In principle, we can convert everything to double (so use -1 to 1 as a default).
			
            supportedRanges = subsystem.RangesAvailable;
            if isempty(supportedRanges)
                % Haven't instantiated the base class yet -- call
                % messageID direct
                error(message('daq:Channel:deviceDoesNotSupportChannelType'))
            end
            
            obj@daq.AudioChannel(daq.internal.SubsystemType.AudioOutput,...
                session,...
                deviceInfo,...
                id,...
                supportedRanges);                        
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
        function outputTypeDisplayText = getOutputTypeDisplayHook(obj)
            % getInputTypeDisplayHook A function that returns the string to
            % display the input type in the display operation
            outputTypeDisplayText = 'AudioGeneration';
        end
    end
    % Protected properties
    properties(SetAccess = protected, GetAccess = protected)
        % Internal property that handle changes in public settings
        PropertyChangeInProgress
    end

    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'audio output channel';
        end
    end
end
