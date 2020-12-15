classdef (Hidden) AnalogOutputChannel < daq.AnalogChannel
    %AnalogOutputChannel All settings & operations for an analog output channel added to a session.
    %    This class is specialized for each class of analog output channel that is
    %    possible.  Vendors further specialize those to implement
    %    additional behaviors.
    
    % Copyright 2010-2011 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
   
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogOutputChannel(session,deviceInfo,id,supportedUnits)
            %AnalogOutputChannel All settings & operations for an analog output channel added to a session.
            %    AnalogOutputChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID,SUPPORTEDUNITS) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel), with a string SUPPORTEDUNITS
            %    defining the units supported by this channel
            %    ('volts','amps', etc.)
            
            % Get the ranges from the device subsystem that are of the
            % correct units.
            subsystem = deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogOutput);
            if isempty(subsystem)
                % Haven't instantiated the base class yet -- call
                % messageID direct
                error(message('daq:Channel:deviceDoesNotSupportChannelType'))
            end
            supportedRanges = subsystem.RangesAvailable.filterByUnits(supportedUnits);
            if isempty(supportedRanges)
                % Haven't instantiated the base class yet -- call
                % messageID direct
                error(message('daq:Channel:deviceDoesNotSupportChannelType'))
            end
            
            obj@daq.AnalogChannel(daq.internal.SubsystemType.AnalogOutput,...
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
            outputTypeDisplayText = obj.TerminalConfigInfo.getShortName();
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
            channelDescriptionText = 'analog output channel';
        end
    end
end
