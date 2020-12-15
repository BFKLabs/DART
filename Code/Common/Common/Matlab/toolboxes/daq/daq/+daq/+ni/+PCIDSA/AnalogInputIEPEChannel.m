classdef (Hidden) AnalogInputIEPEChannel < daq.ni.AnalogInputIEPEChannel & daq.ni.DSACommonChannelAttrib
    %AnalogInputIEPEChannel All settings & operations for an NI PCI DSA
    %analog input IEPE channel.The DSACommonChannelAttrib provides the
    %common functionality for all DSA devices.
    
    % Copyright 2012 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputIEPEChannel(session,deviceInfo,channelID)
            %AnalogInputIEPEChannel All settings & operations for a NI PCI
            %DSA analog input IEPE channel added to a session.
            %    AnalogInputIEPEChannel(SESSION,DEVICEINFO,CHANNELID) Create a
            %    analog channel with SESSION, DEVICEINFO,
            %    and CHANNELID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.AnalogInputIEPEChannel(session,deviceInfo,channelID);
            obj@daq.ni.DSACommonChannelAttrib();
        end
    end
    
    % Destructor
    methods(Access=protected)
        % Needed just to keep the access settings for all destructors
        % consistent (it'd be "public" if it were deleted.
        function delete(~)
        end
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
    end
    
    % Superclass methods this class implements
    methods (Hidden, Sealed, Access = protected)
        function [groupName] = getGroupNameHook(obj)
            % Define the group name for this channel.
            %
            % Override the default group name assignment.
            % The group name is based on the AutoSyncDSA property setting.
            % When AutoSyncDSA is true, all the PCI DSA boards in a session
            % need to be synchronized and are therefore put in a single NI
            % task. We do this by assigning it a common groupName which is
            % dependent on the RTSI cable being used.
            if obj.Session.AutoSyncDSA
                groupName = ['ai/RTSI' num2str(obj.Device.RTSICable)];
            else
                groupName = ['ai/' obj.Device.ID];
            end
        end
        
        function [session] = getSession(obj)
            session = obj.Session;
        end         
    end
    
    % override the base class methods
    methods(Hidden)
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelAndCaptureParameters@daq.ni.AnalogInputVoltageChannel(taskHandle);
            obj.captureDSACommonChannelAttribFromNIDAQmx(taskHandle);
        end
        
        function onTaskRecreationHook(obj,taskHandle)
             obj.onDSATaskRecreationHook(taskHandle)
        end
    end
    
    methods (Access = protected)
        function DSAPropertyBeingChangedImpl(obj,propertyName,newValue)
            obj.DSAPropertyBeingChangedHook(propertyName,newValue,obj.Session)
        end

    end
end
