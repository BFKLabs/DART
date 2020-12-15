classdef (Hidden) PXIDSAModule < daq.ni.PXIModule
    %PXIModule Device info for National Instruments PXI modules.
    %
    %    This class represents PXI modules by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2012 The MathWorks, Inc.
    
    % Specializations of the daq.DeviceInfo class should call addSubsystem
    % repeatedly to add a SubsystemInfo record to their device. usage:
    % addSubsystem(SUBSYSTEM) adds an adaptor specific SubsystemInfo record
    % SUBSYSTEM to the device.
    
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = PXIDSAModule(vendor,device)
            % Call the superclass constructor
            obj@daq.ni.PXIModule(vendor, device);
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function suffixText = getSingleDispSuffixHook(obj)
            %getSingleDispSuffixImpl Subclasses override to customize disp
            %suffixText = getSingleDispSuffixImpl() Optional override by
            %DeviceInfo subclasses to allow them to append custom
            %information to the disp of a single DeviceInfo object.
            
            suffixText = sprintf('This module is in slot %s of the PXI Chassis %s.',...
                num2str(obj.SlotNumber),num2str(obj.ChassisNumber));
        end
    end
    
    methods(Hidden, Static)
        function result = findPXImodulesInSession(session)
            devicesInSession = [session.Channels.Device];
            
            result = daq.DeviceInfo.empty;
            for iDevice = 1:numel(devicesInSession)
                if isa(devicesInSession(iDevice),'daq.ni.PXIDSAModule') && ...
                        (isempty(result) || ~any(strcmp({result.ID},devicesInSession(iDevice).ID)))
                    result = [ result devicesInSession(iDevice)]; %#ok<*AGROW>
                end
            end
        end
        
        function result = findPXIChannelsInSession(session)
           devicesInSession = [session.Channels.Device];
            result = devicesInSession(...
                arrayfun(@(x) isa(x,'daq.ni.PXIDSAModule'),devicesInSession));
        end
        
    end
    
    methods (Hidden)
        % When synchronizing multiple PXI modules, we can not set any
        % properties associated with sampling, triggering , timing before
        % adding all the devices to the same channel group. Overriding the
        % default createChannelHook to defer setting all the properties in
        % this case.
        function createChannelHook(obj,session,newChannel) %#ok<INUSL>
            
            % Configure the task for this new channel
            taskHandle = session.getUnreservedTaskHandle(newChannel.GroupName);
            newChannel.createChannelAndCaptureParameters(taskHandle)
            
        end
        
        function result = getSpecializedFamily(obj) %#ok<MANU>
            result = 'PXIDSA';
        end
    end
end
