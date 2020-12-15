classdef (Hidden) DigitalChannel < daq.Channel
    %DigitalChannel All settings & operations for a digital channel added
    % to a session. Vendors further specialize digital channels to
    % implement additional behaviors.
    
    % Copyright 2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties that must be implemented by vendors
    properties(Abstract)
        % The Digital channel direction can either be Input or Output.
        Direction
    end
    
    % Should be a protected friend
    properties(Abstract, Hidden, SetAccess = private)
        % The number of lines in a digital channel
        GroupChannelCount;
        
        % Channel ID's in a digital group
        GroupChannelIDs;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = DigitalChannel(session,deviceInfo,channelID)
            %DigitalChannel All settings & operations for a digital
            % channel added to a session.
            
            obj@daq.Channel(daq.internal.SubsystemType.DigitalIO,session,deviceInfo,channelID);
            
            % Get the device subsystem
            subsystem = deviceInfo.getSubsystem(daq.internal.SubsystemType.DigitalIO);
            if isempty(subsystem)
                % Haven't instantiated the base class yet -- call
                % messageID direct
                error(message('daq:Channel:deviceDoesNotSupportChannelType'))
            end

            % Refers to channels by "<device>/<channelID>"
            if ~obj.isGroup
                obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
            else
                obj.PhysicalChannel = [deviceInfo.ID '/' channelID{1}];
                for i = 2:numel(channelID)
                    obj.PhysicalChannel = ...
                        [obj.PhysicalChannel ',' deviceInfo.ID '/' channelID{i}];
                end
            end
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
            resetImpl@daq.Channel(obj);
        end
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'digital channel';
        end
    end
end
