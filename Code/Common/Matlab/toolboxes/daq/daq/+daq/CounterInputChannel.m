classdef (Hidden) CounterInputChannel < daq.CounterChannel
    %CounterInputChannel All settings & operations for an counter input channel added to a session.
    %    This class is specialized for each class of counter input channel that is
    %    possible.  Vendors further specialize those to implement
    %    additional behaviors.
    
    % Copyright 2010-2011 The MathWorks, Inc.
    % $Revision: 1.1.6.5 $  $Date: 2011/06/27 19:47:59 $
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = CounterInputChannel(session,deviceInfo,channelID)
            %CounterInputChannel All settings & operations for a counter
            %input channel added to a session.
            
            % Get the device subsystem
            subsystem = deviceInfo.getSubsystem(daq.internal.SubsystemType.CounterInput);
            if isempty(subsystem)
                % Haven't instantiated the base class yet -- call
                % messageID direct
                error(message('daq:Channel:deviceDoesNotSupportChannelType'))
            end
            
            obj@daq.CounterChannel(daq.internal.SubsystemType.CounterInput,...
                session,...
                deviceInfo,...
                channelID);

            % NI-DAQmx refers to channels by "<device>/<channelID>"
            obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
        end
    end
   
    % Property access methods
    methods
    end
        
    % Protected properties
    properties(SetAccess = protected, GetAccess = protected)
        % Internal property that handle changes in public settings
        PropertyChangeInProgress
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
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
            channelDescriptionText = 'counter input channel';
        end
    end
    
    methods (Abstract)
        resetCounter(obj)
    end
end
