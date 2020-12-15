classdef (Hidden) AnalogInputChannel < daq.AnalogChannel
    %AnalogInputChannel All settings & operations for an analog input channel added to a session.
    %    This class is specialized for each class of analog input channel that is
    %    possible.  Vendors further specialize those to implement
    %    additional behaviors.
    
    % Copyright 2010-2011 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputChannel(session,deviceInfo,id,supportedUnits)
            %AnalogInputChannel All settings & operations for an analog input channel added to a session.
            %    AnalogInputChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID,SUPPORTEDUNITS) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel), with a string SUPPORTEDUNITS
            %    defining the units supported by this channel
            %    ('volts','amps', etc.)

            % Get the ranges from the device subsystem that are of the
            % correct units.
            subsystem = deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogInput);
            if isempty(subsystem)
                % Haven't instantiated the base class yet -- call
                % messageID direct
                error(message('daq:Channel:deviceDoesNotSupportChannelType'))
            end
            % The device subsystem may support units that the channel
            % doesn't.  For instance, a voltage channel won't support a
            % range in milliamps.
            
            supportedRanges = subsystem.RangesAvailable.filterByUnits(supportedUnits);
            
            if isempty(supportedRanges)
                % Haven't instantiated the base class yet -- call
                % messageID direct
                error(message('daq:Channel:deviceDoesNotSupportChannelType'))
            end

            obj@daq.AnalogChannel(daq.internal.SubsystemType.AnalogInput,...
                session,...
                deviceInfo,...
                id,...
                supportedRanges);
            
            obj.PropertyChangeInProgress = false;
        end
    end
    
    % Protected properties
    properties(SetAccess = protected, GetAccess = protected)
        % Internal property that handle changes in public settings
        PropertyChangeInProgress
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function inputTypeDisplayText = getInputTypeDisplayHook(obj)
            % getInputTypeDisplayHook A function that returns the string to
            % display the input type in the display operation
            inputTypeDisplayText = obj.TerminalConfigInfo.getShortName();
        end
        
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'analog input channel';
        end
    end
end
