classdef (Hidden) PCIDSADevice < daq.ni.DeviceInfo
    %DSADevice Device info for National Instruments PCI DSA modules.
    %
    %    This class represents the Dynamic Signal Analyzers DSA with PCI
    %    form factor by National Instruments.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2012 The MathWorks, Inc.
    
    % Specializations of the daq.DeviceInfo class should call addSubsystem
    % repeatedly to add a SubsystemInfo record to their device. usage:
    % addSubsystem(SUBSYSTEM) adds an adaptor specific SubsystemInfo record
    % SUBSYSTEM to the device.
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        % RTSICable The registered RTSI cable number connected to the
        % device in MAX
        RTSICable;
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = PCIDSADevice(vendor,device)
            % Call the superclass constructor
            obj@daq.ni.DeviceInfo(vendor, device);
        end
    end
    
    methods (Hidden, Static)
        % This method tries to find all the RTSI cables connected and
        % registered in MAX. NI drivers give you no direct way to query for
        % all connected RTSI cables. This algorithm loops through all PCI
        % DSA devices to find the ones that are connected together and then
        % assigns it a unique number.
        function findAndAddRegsiteredRTSIcables

            % g873066,873097,885613: Fixed LXE incompatibility warnings
            HardwareInfo = daq.HardwareInfo.getInstance(); 
            devices = HardwareInfo.Devices;
            PCIDSAdevices = devices(arrayfun(@(x) isa(x,'daq.ni.PCIDSADevice'), devices));
            
            % Simply return if no PCIDSA devices found.
            if isempty(PCIDSAdevices)
                return;
            end

            % Start RTSI bus numbering with 1.
            RTSIcable = 1;
            
            % Reset all RTSI cables to empty 
            [PCIDSAdevices(:).RTSICable] = deal([]);
            
            for iPCIDSAdevice = 1:numel(PCIDSAdevices)
                dut = PCIDSAdevices(iPCIDSAdevice);
                RTSIcable = RTSIcable + 1;
                for j = iPCIDSAdevice:numel(PCIDSAdevices)                    
                    if (isRTSIRegisteredBetweenDevices(dut,PCIDSAdevices(j)))
                        % If empty (i.e. connected to a previously
                        % unidentified RTSI cable), assign a unique number.
                        if isempty(dut.RTSICable)
                            dut.RTSICable = RTSIcable;
                        end
                        PCIDSAdevices(j).RTSICable = dut.RTSICable;
                    end
                end
            end
            
            % Find if there is any RTSI cable between these devices. We use
            % the DAQmxConnectTerms to find if a connection is possible
            % between the two PCI device terminals.
            function result = isRTSIRegisteredBetweenDevices(dev1,dev2)
                result = false;
                
                % Try connecting two device terminals together.
                [ status ] = daq.ni.NIDAQmx.DAQmxConnectTerms(['/' dev1.ID '/RTSI0'],['/' dev2.ID '/RTSI0'],daq.ni.NIDAQmx.DAQmx_Val_DoNotInvertPolarity);
                
                if status == daq.ni.NIDAQmx.DAQmxSuccess
                    result = true;
                end
                
                % Destroy the connection
                [~] = daq.ni.NIDAQmx.DAQmxDisconnectTerms(['/' dev1.ID '/RTSI0'],['/' dev2.ID '/RTSI0']);
                
            end
            
        end
    end
    
    methods ( Hidden )
        % This method checks if a PCI device being added to the session
        % shares a RTSI cable with the existing PCI devices. This method is
        % used in the AutoSyncDSA mode, when adding a PCI device that does not
        % share any RTSI cable should error out.
        function verifyIfDeviceCanBeAddedInAutoSyncDSA(obj,session)
            
            PCIDSADevicesExistingInSession = daq.ni.PCIDSADevice.findPCIdevicesInSession(session);
            if isempty(PCIDSADevicesExistingInSession)
                % No further checking required if this is the first DSA
                % device to be added.
                return;
            end
            
            RTSICableUsedInSession = unique([PCIDSADevicesExistingInSession.RTSICable] );
            deviceBeingAddedRTSICable = obj.RTSICable;
            
            if isempty(RTSICableUsedInSession) || ...
                    isempty(deviceBeingAddedRTSICable) || ...
                    (RTSICableUsedInSession ~= deviceBeingAddedRTSICable)
                    obj.throwNoRTSIConnectedError( ...
                        obj.renderCellArrayOfStringsToString({PCIDSADevicesExistingInSession.ID},''' , '''),...
                        obj.ID);                 
            end
        end
        
        function verifyValidAutoSyncDSASetup(obj,session)
            
            PCIDSADevicesInSession = daq.ni.PCIDSADevice.findPCIdevicesInSession(session);
            if numel(PCIDSADevicesInSession) == 1
                % No further checking required if there is only one PCI DSA
                % device in session.
                return;
            end
            
            RTSICablesUsedInSession = unique([PCIDSADevicesInSession.RTSICable] );
            
            if isempty(RTSICablesUsedInSession) || ...
                    numel(RTSICablesUsedInSession) ~= 1
                    obj.throwNoRTSIConnectedError (...
                        obj.renderCellArrayOfStringsToString({PCIDSADevicesInSession(1:end-1).ID},''' , '''),...
                        PCIDSADevicesInSession(end).ID);
            end
            
        end
        
        function throwNoRTSIConnectedError(obj,devicesAlreadyInSession,newDevice)
            % In some contexts, such as publishing, you cannot use
            % hyperlinks.  If hotlinks is true, then you can.
            hotlinks = feature('hotlinks');
            if hotlinks
                link = obj.getLocalizedText('nidaq:ni:DSASyncDocumentationLink');                
            else
                link = '';
            end
       
            
            obj.localizedError('nidaq:ni:noRTSIfound',...  
                 devicesAlreadyInSession,...
                 newDevice,...
                 link);           
             
        end
        
    end
    methods(Static, Hidden)
        function result = findPCIdevicesInSession(session)
            devicesInSession = [session.Channels.Device];
            
            result = daq.DeviceInfo.empty;
            for iDevice = 1:numel(devicesInSession)
                if isa(devicesInSession(iDevice),'daq.ni.PCIDSADevice') && ...
                   (isempty(result) || ~any(strcmp({result.ID},devicesInSession(iDevice).ID)))
                result = [ result devicesInSession(iDevice)]; %#ok<*AGROW>
                end                
            end            
        end
        
        function result = findPCIChannelsInSession(session)
            
            devicesInSession = [session.Channels.Device];
            result = devicesInSession(...
                arrayfun(@(x) isa(x,'daq.ni.PCIDSADevice'),devicesInSession));          
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
            newChannel.createChannelAndCaptureParameters(taskHandle);
        end
        
        
        function result = getSpecializedFamily(obj) %#ok<MANU>
            result = 'PCIDSA';
        end
    end
end
