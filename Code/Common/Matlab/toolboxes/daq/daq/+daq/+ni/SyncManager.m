classdef (Hidden) SyncManager < daq.SyncManager
    %SyncManager SyncManager for National Instruments DAQ.
    %
    %    This class contains all vendor-specific code to managing trigger
    %    and clock connections.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2011-2012 The MathWorks, Inc.
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    %% Hidden constructor
    
    methods(Hidden)
        function obj = SyncManager(session)
            obj@daq.SyncManager(session);
        end
    end
    
    
    %% Superclass methods this class implements
    methods (Hidden,  Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end
    
    %% Superclass methods this class implements
    methods ( Access = protected )
        
        function connectionBeingAddedImpl(obj,newConnection)
            % Get the device and terminal used by the other existing
            % connections of the same type
            [oldSourceDevice, oldSourceTerminal] = ...
                obj.getSourceDeviceAndTerminalForConnectionType(newConnection.Type);
            
            % Get the device and terminal for the new connection
            newSource = newConnection.getSourceDevice();
            newTerminal = daq.DeviceTerminalPair.getTerminal(newConnection.Source);
            
            % Error out if different source device is being used for the
            % new connection of the same type
            if ~strcmp(oldSourceDevice,daq.SyncManager.NoDeviceSet) && ~strcmp(newSource,oldSourceDevice)
                obj.localizedError('nidaq:ni:oneSourceDevicePerSession',...
                    newConnection.getConnectionFullName,...
                    newSource,...
                    oldSourceDevice);
            end
            
            % Error out if different source terminal is being used for the
            % new connection of the same type
            if ~strcmp(oldSourceTerminal,daq.SyncManager.NoDeviceSet) && ~strcmp(newTerminal,oldSourceTerminal)
                obj.localizedError('nidaq:ni:differentTerminalForSourceDevice',...
                    newTerminal,...
                    newConnection.getConnectionFullName,...
                    oldSourceTerminal);
            end
            
            % Get the source device for the other connection type. Source
            % and Destination devices for Start Trigger and Scan Clock can
            % only be different if one of them is 'External'.
            if isa(newConnection.Type,'daq.ni.TriggerConnectionType')
                [otherSourceDevice, otherSourceTerminal] = ...
                    getSourceDeviceAndTerminalForConnectionType(obj,daq.ni.ClockConnectionType.ScanClock);
            else
                [otherSourceDevice, otherSourceTerminal] = ...
                    getSourceDeviceAndTerminalForConnectionType(obj,daq.ni.TriggerConnectionType.StartTrigger);
            end
            
            if ~strcmp(otherSourceDevice,daq.SyncManager.NoDeviceSet) &&...
                    ~strcmp(otherSourceDevice,daq.SyncManager.ExternalDevice) && ...
                    ~strcmp(newSource,daq.SyncManager.ExternalDevice) && ...
                    ~strcmp(otherSourceDevice,newSource)
                obj.localizedError('nidaq:ni:differentSourceDeviceOnlyForExternal',...
                    newSource,...
                    otherSourceDevice);
            end
            
            % If the source device for new connection is same as source
            % device for the other connection type, verify that the
            % terminals used by them are different.
            if strcmp(otherSourceDevice,newSource) && ...
                    strcmp(otherSourceTerminal,newTerminal) && ...
                    ~strcmp(newSource,daq.SyncManager.ExternalDevice)
                obj.localizedError('nidaq:ni:sameTerminalUsed',...
                    newTerminal,...
                    newSource);
            end
            
            newDestination = newConnection.getDestinationDevice();
            
            % g770941 Error out if a DSA device is being used as a
            % destination device for clock connections
            if ~strcmpi(newDestination,daq.SyncManager.ExternalDevice)
                [status,productCategory] = ...
                    daq.ni.NIDAQmx.DAQmxGetDevProductCategory(newDestination,int32(0));
                if (status ~= daq.ni.NIDAQmx.DAQmxSuccess || ...
                        productCategory == daq.ni.NIDAQmx.DAQmx_Val_DynamicSignalAcquisition) && ...
                        isa(newConnection,'daq.ni.ScanClockConnection')
                    obj.localizedError('nidaq:ni:sampleClockSyncNotSupportedWithDSA',newDestination)
                end
            end
            % Check if an connection already exists between the source and
            % destination for the same type.
            conn = obj.getConnectionsOfType(newConnection.Type);
            for iConn = 1:numel(conn)
                destinationDevice = conn(iConn).getDestinationDevice();
                if strcmp(destinationDevice,newDestination)
                    obj.localizedError('nidaq:ni:sameConnectionAlreadyAdded',...
                        char(newConnection.Type),...
                        newSource,...
                        newDestination);
                end
            end
            
            % Error out if the source and destination device is the same
            if strcmp(newDestination, newSource)
                obj.localizedError('nidaq:ni:sameSourceAndDestinationDevice',newSource);
            end
            
            obj.validateDSAConnection(newSource,newDestination);
        end
        
        function result = validateAndCorrectSourceHook(obj, source)
            result  = obj.validateAndCorrectSyncItem('source', source);
            
        end
        
        function result = validateAndCorrectDestinationHook(obj,destination)
            result  = obj.validateAndCorrectSyncItem('destination', destination);
        end
        
        function result = validateAndCorrectTriggerTypeHook(obj,type)  %#ok<INUSL>
            if strcmpi(type,'StartTrigger')
                result = daq.ni.TriggerConnectionType.setValue('StartTrigger');
            else
                result = daq.ni.TriggerConnectionType.setValue(type);
            end
        end
        
        function result = validateAndCorrectClockTypeHook(obj,type)  %#ok<INUSL>
            if strcmpi(type,'ScanClock')
                result = daq.ni.ClockConnectionType.setValue('ScanClock');
            else
                result = daq.ni.ClockConnectionType.setValue(type);
            end
        end
        
        function result = getSessionConnectionSummaryTextHook(obj)
            numClockConnections = obj.countConnectionsOfType(daq.ni.ClockConnectionType.ScanClock);
            numTriggerConnections = obj.countConnectionsOfType(daq.ni.TriggerConnectionType.StartTrigger);
            
            if ~(numTriggerConnections + numClockConnections > 0)
                result = '';
                return;
            end
            
            if (numTriggerConnections >= 1) && (numClockConnections == 0)
                % Only Triggers added
                result = obj.getLocalizedText('daq:Conn:dispOnlyTriggers');
            elseif (numClockConnections >= 1) && (numTriggerConnections == 0)
                % Only Clocks added
                result = obj.getLocalizedText('daq:Conn:dispOnlyClocks');
            else
                % Both clocks and triggers added
                result = obj.getLocalizedText('daq:Conn:dispClocksAndTriggers');
            end
            
            if (numClockConnections + numTriggerConnections > 1)
                result = [ result ' ' obj.getLocalizedText('daq:Conn:dispMultipleConnections')];
            else
                result = [ result ' ' obj.getLocalizedText('daq:Conn:dispSingleConnection')];
            end
            
        end
        
        function [ result ] = getConnectionDispSummaryTextHook(obj)
            % Display trigger connections
            triggerResult = '';
            triggerConnections = obj.getConnectionsOfType(daq.ni.TriggerConnectionType.StartTrigger);
            if ~isempty(triggerConnections)
                triggerResult = dispCombinedConnection(triggerConnections);
            end
            
            % Display clock connections
            clockConnections = obj.getConnectionsOfType(daq.ni.ClockConnectionType.ScanClock);
            clockResult = '';
            if ~isempty(clockConnections)
                clockResult = dispCombinedConnection(clockConnections);
            end
            
            result = [ triggerResult clockResult];
            
            function result = dispCombinedConnection(connection)
                % If there is only a single connection, delegate display work
                % to connection disp.
                if numel(connection) == 1
                    result = connection.getConnectionDescriptionHook();
                    return
                end
                
                [sourceDevice, sourceTerminal] = ....
                    obj.getSourceDeviceAndTerminalForConnectionType(connection(1).Type);
                [destinationDevices, destinationTerminals] = ...
                    obj.getDestinationDevicesAndTerminalsForConnectionType(connection(1).Type);
                
                % Display the connection type full name
                connectionTypeFullName = connection.getConnectionFullName();
                result = connectionTypeFullName;
                
                
                if strcmpi(sourceDevice,daq.SyncManager.ExternalDevice)
                    % If the source is external, the display should look like
                    %
                    %  'is provided externally and will be received by:'
                    %
                    result = [ result, ' ' , obj.getLocalizedText('nidaq:ni:externalSourceVerbalDisp'),':'];
                else
                    % If the source & destination are both not external,
                    % the display should look like -
                    %
                    %  'is provided by '' at '' and will be
                    %  received by:'
                    %
                    result = [ result, ' ',obj.getLocalizedText('nidaq:ni:sourceVerbalDisp',sourceDevice,sourceTerminal),':'];
                end
                
                % Loop through all the destination devices
                for iConn = 1:numel(destinationDevices)
                    if strcmp(destinationDevices{iConn},daq.SyncManager.ExternalDevice)
                        result = [ result, '\n',obj.indentText(obj.getLocalizedText('nidaq:ni:singleExternalDestinationVerbalDisp'),...
                            3*daq.internal.BaseClass.StandardIndent)] ; %#ok<AGROW>
                    else
                        result = [ result,'\n',obj.indentText(obj.getLocalizedText('nidaq:ni:connectionDestinationVerbalDisp',destinationDevices{iConn},destinationTerminals{iConn}),...
                            3*daq.internal.BaseClass.StandardIndent)]; %#ok<AGROW>
                    end
                end
                
                result = [ result,'\n'];
                
            end
        end
    end
    
    methods ( Access = public, Hidden )
        
        function checkForUnderdefinedSystem(obj)
            
            % Check for start trigger connections
            checkForType(daq.ni.TriggerConnectionType.StartTrigger);
            
            % Check for scan clock connections
            checkForType(daq.ni.ClockConnectionType.ScanClock);
            
            function checkForType(type)
                [source, ~ ] = obj.getSourceDeviceAndTerminalForConnectionType(type);
                if ~strcmp(source,daq.SyncManager.NoDeviceSet)
                    [destination, ~] = obj.getDestinationDevicesAndTerminalsForConnectionType(type);
                    allSyncItemsInSession = obj.getRequiredSyncItemsInSession();
                    for iAllSyncItemsInSession = 1:numel(allSyncItemsInSession)
                        if ~any(strcmp([source,destination],allSyncItemsInSession(iAllSyncItemsInSession).ID)) && ...
                                ~strcmp(destination,daq.SyncManager.ExternalDevice)
                            obj.localizedError('nidaq:ni:underdefinedSession',...
                                char(type),...
                                allSyncItemsInSession(iAllSyncItemsInSession).ID)
                        end
                    end
                end
            end
            
        end
        
        function result = configurationRequiresExternalTriggerImpl(obj)
            
            % Check if there are only counter outputs. co
            % channels are not synchronized and we do not wait for
            % external trigger in that scenario
            if obj.Session.Channels.countChannelsOfType('daq.CounterOutputChannel') == numel(obj.Session.Channels)
                result = 0;
                return;
            end
            
            [source, ~ ] = getSourceDeviceAndTerminalForConnectionType(obj,daq.ni.TriggerConnectionType.StartTrigger);
            result = strcmp(source,daq.SyncManager.ExternalDevice);
            
            
        end
        
        function syncInfo  = configureChannelGroup(obj,cg,parentSubsystemSyncInfo)
            
            %Default is to pass back the parent subsystem's syncInfo
            syncInfo = parentSubsystemSyncInfo;
            
            for iConn = 1:numel(obj.Session.Connections)
                conn = obj.Session.Connections(iConn);
                destinationDevice = conn.getDestinationDevice();
                sourceDevice =  conn.getSourceDevice();
                
                % get exported scan clock from connections
                if strcmp(parentSubsystemSyncInfo.ExportedScanClock,daq.SyncManager.Default)
                    if strcmp(sourceDevice,cg.DeviceID) && ...
                            isa(conn,'daq.ni.ScanClockConnection')
                        syncInfo.ExportedScanClock = [ '/' conn.Source ];
                    end
                end
                
                % get exported start trigger
                if strcmp(parentSubsystemSyncInfo.ExportedStartTrigger,daq.SyncManager.Default)
                    if strcmp(sourceDevice,cg.DeviceID) && ...
                            isa(conn,'daq.ni.StartTriggerConnection')
                        syncInfo.ExportedStartTrigger = [ '/' conn.Source ];
                    end
                end
                
                % get scan clock
                if strcmp(destinationDevice,cg.DeviceID) &&  ...
                        isa(obj.Session.Connections(iConn),'daq.ni.ScanClockConnection')
                    syncInfo.ScanClock = [ '/' conn.Destination ];
                end
                
                % get start trigger
                if strcmp(destinationDevice,cg.DeviceID) &&  ...
                        isa(obj.Session.Connections(iConn),'daq.ni.StartTriggerConnection')
                    syncInfo.StartTrigger = [ '/' conn.Destination ];
                    syncInfo.StartTriggerCondition = conn.TriggerConditionInfo;
                end
            end
        end
    end
    
    
    methods( Access = public, Hidden )
        
        function result = validateAndCorrectSyncItem(obj,propertyBeingValidated,deviceTerminalPair)
            
            % No validation is required when the source or destination
            % device is external.
            if strcmpi(deviceTerminalPair,daq.SyncManager.ExternalDevice)
                result = daq.SyncManager.ExternalDevice;
                return;
            end
            
            [deviceIDOrChassis, terminal ] = daq.DeviceTerminalPair.split(deviceTerminalPair);
            
            % Check if valid Sync device
            syncItems = obj.getAvailableSyncItems;
            theDevice = syncItems.locate(obj.Session.Vendor.ID,deviceIDOrChassis);
            if isempty(theDevice)
                validValues = obj.renderCellArrayOfStringsToString({syncItems.ID},''' , ''');
                obj.localizedError('nidaq:ni:unknownSourcesDestinations',...
                    deviceIDOrChassis,...
                    propertyBeingValidated,...
                    propertyBeingValidated,...
                    validValues)
            end
            
            % Check if a channels exists for the sync item in session
            syncItemsInSession = obj.getAvailableSyncItemsInSession();
            theDevice = syncItemsInSession.locate(obj.Session.Vendor.ID,deviceIDOrChassis);
            if isempty(theDevice)
                obj.localizedError('nidaq:ni:noChannels',deviceIDOrChassis)
            end
            
            % Check if it is a valid terminal on the source device
            terminal = obj.validateAndCorrectTerminal(theDevice,terminal);
            
            result = daq.DeviceTerminalPair.reconstruct(theDevice.ID,terminal);
            
        end
        
        function terminal = validateAndCorrectTerminal(obj,theDevice,terminal)
            
            % In case of a compactDAQ chassis, there exists terminals for
            % both chassis and module on the device object. Find the
            % terminals for the particular chassis/device/module specified
            % for the connection in the list of terminals on the device
            % object.
            splitStrings = regexpi(theDevice.Terminals,[theDevice.ID,'/'],'split');
            
            % If a match is found, regexpi returns a cell array of the two
            % split strings. The second string is the terminal. If no match
            % is found, it returns the cell array of the entire string. So
            % in order to find the terminals for a particular device, get
            % the second string of all 1 X 2 cell arrays
            availableTerminalsForDevice = {};
            for index = 1:numel(splitStrings)
                stringBeingTested = splitStrings{index};
                if size(stringBeingTested,2) == 2
                    availableTerminalsForDevice = [ availableTerminalsForDevice stringBeingTested{2}]; %#ok<AGROW>
                end
            end
            
            matchingTerminals = strcmpi(terminal,availableTerminalsForDevice);
            if isempty(availableTerminalsForDevice)
                obj.localizedError('nidaq:ni:noTerminals',theDevice.ID);
            end
            if ~any(matchingTerminals)
                obj.localizedError('nidaq:ni:unknownTerminal',...
                    terminal,...
                    theDevice.ID,...
                    daq.internal.renderCellArrayOfStringsToString(availableTerminalsForDevice,''', '''))
            end
            terminal = availableTerminalsForDevice{matchingTerminals};
        end
        
        function syncItemsInSession = getAvailableSyncItemsInSession(obj)
            syncItemsInSession = daq.DeviceInfo.empty();
            
            for iChannel = 1:numel(obj.Session.Channels)
                device = obj.Session.Channels(iChannel).Device;
                
                if isa(device,'daq.ni.CompactDAQModule')
                    % we need to add all the modules if one compact module is
                    % added as well as the chassis
                    chassis = daq.ni.CompactDAQChassis(obj.Session.Vendor,device.ChassisName);
                    device = [ chassis, chassis.findModules()];
                end
                
                for iDevice = 1:numel(device)
                    if isempty(syncItemsInSession) || ~any(strcmp({syncItemsInSession(:).ID}, device(iDevice).ID))
                        syncItemsInSession = [ syncItemsInSession device(iDevice)]; %#ok<AGROW>
                    end
                end
            end
        end
        
        function syncItemsInSession = getRequiredSyncItemsInSession(obj)
            syncItemsInSession = daq.DeviceInfo.empty();
            for iChannel = 1:numel(obj.Session.Channels)
                device = obj.Session.Channels(iChannel).Device;
                if isa(device,'daq.ni.CompactDAQModule')
                    device = daq.ni.CompactDAQChassis(obj.Session.Vendor,device.ChassisName);
                end
                if isempty(syncItemsInSession) || ~any(strcmp({syncItemsInSession(:).ID}, device.ID))
                    syncItemsInSession = [ syncItemsInSession device]; %#ok<AGROW>
                end
            end
        end
        
        function syncItems = getAvailableSyncItems(obj)
            
            % Get all devices that are recognized by the DAQ excluding
            % cDAQ modules

            % g873066,873097,885613: Fixed LXE incompatibility warnings
            HardwareInfo = daq.HardwareInfo.getInstance(); 
            devices = HardwareInfo.Devices;
             
            % Add available chassis names to the list of available syncItems
            syncItems = [obj.getAvailableChassis devices ];
            
        end
        
        function availableChassisIDs = getAvailableChassis(obj) %#ok<MANU>
            
            availableChassisIDs = daq.ni.CompactDAQChassis.empty;

            % g873066,873097,885613: Fixed LXE incompatibility warnings
            HardwareInfo = daq.HardwareInfo.getInstance(); 
            devices = HardwareInfo.Devices;

            chassisModules = devices(arrayfun(@(x) isa(x,'daq.ni.CompactDAQModule'), devices));
            for iChassisModules = 1:numel(chassisModules)
                chassisName = chassisModules(iChassisModules).ChassisName;
                if isempty(availableChassisIDs) || ~any(strcmpi({availableChassisIDs.ID},chassisName))
                    availableChassisIDs = [availableChassisIDs daq.ni.CompactDAQChassis(chassisModules(iChassisModules).Vendor,chassisName)]; %#ok<AGROW>
                end
            end
        end
        
        function devices = getDevicesWithoutConnections(obj)
            % Get devices which do not have any connections attached to
            % them.
            devices = {};
            sourceDevice = obj.getSourceDevice;
            destinationDevices = obj.getDestinationDevices;
            syncItemsInSession = getRequiredSyncItemsInSession(obj);
            for iSyncItems = 1:numel(syncItemsInSession)
                if ~strcmp(sourceDevice, syncItemsInSession(iSyncItems).ID) && ...
                        ~any(strcmp(destinationDevices, syncItemsInSession(iSyncItems).ID))
                    devices = [devices syncItemsInSession(iSyncItems).ID]; %#ok<AGROW>
                end
            end
        end
        
        function destinationDevices = getDestinationDevices(obj)
            % Get devices which act as destination for all the connections
            destinationDevices = {};
            for iConn = 1:numel(obj.Session.Connections)
                destinationDeviceForConn = obj.Session.Connections(iConn).getDestinationDevice();
                if ~any(strcmp(destinationDevices,destinationDeviceForConn))
                    destinationDevices = [destinationDevices destinationDeviceForConn]; %#ok<AGROW>
                end
                
            end
            
            
        end
        
        function sourceDevice = getSourceDevice(obj)
            % Get the source device for triggers and clocks
            
            [sourceDeviceForTriggers, ~] = ...
                getSourceDeviceAndTerminalForConnectionType(obj,daq.ni.TriggerConnectionType.StartTrigger);
            
            [sourceDeviceForClocks, ~] = ...
                getSourceDeviceAndTerminalForConnectionType(obj,daq.ni.ClockConnectionType.ScanClock);
            
            % The source device for clock and trigger can be different only
            % when one of them is 'External'.
            if strcmp(sourceDeviceForTriggers,daq.SyncManager.ExternalDevice)
                sourceDevice = sourceDeviceForClocks;
            else
                sourceDevice = sourceDeviceForTriggers;
            end
        end
        
        function validateAllDSAConnections(obj)
            for iConnections = 1: numel(obj.Session.Connections)
                source =  obj.Session.Connections(iConnections).getSourceDevice();
                destination = obj.Session.Connections(iConnections).getDestinationDevice();
                try
                    obj.validateDSAConnection(source,destination);
                catch e
                    if strcmp(e.identifier,'nidaq:ni:invalidManualConnectionWithAutoSync')
                        obj.localizedError('nidaq:ni:invalidAutoSyncWithManualConnection',...
                            source,...
                            destination)
                    else
                        rethrow(e)
                    end
                end
            end
            
        end
        
        
        function validateDSAConnection(obj,newSource,newDestination)
            if obj.Session.AutoSyncDSA
                
                PCIdevicesInSession = daq.ni.PCIDSADevice.findPCIdevicesInSession(obj.Session);
                PXImodulesInSession = daq.ni.PXIDSAModule.findPXImodulesInSession(obj.Session);
                
                % g873066,873097,885613: Fixed LXE incompatibility warnings
                HardwareInfo = daq.HardwareInfo.getInstance(); 
                devices = HardwareInfo.Devices;

                newDestinationDevice = devices.locate('ni',newDestination);
                newSourceDevice =   devices.locate('ni',newSource);
                
                % Does newDestination and newSource belong to PCI devices
                % on Session
                if  ~isempty(PCIdevicesInSession) && ...
                        (any(strcmp({PCIdevicesInSession.ID},newDestination)) && ...
                        any(strcmp({PCIdevicesInSession.ID},newSource)))
                    obj.localizedError('nidaq:ni:invalidManualConnectionWithAutoSync',...
                        newSource,...
                        newDestination)
                end
                
                %Does newDestination and newSource belong to same PXI chassis on Session
                if  ~isempty(PXImodulesInSession) && ...
                        ( any(strcmp({PXImodulesInSession.ID},newDestination)) && ...
                        any(strcmp({PXImodulesInSession.ID},newSource)) && ...
                        newDestinationDevice.ChassisNumber == newSourceDevice.ChassisNumber )
                    obj.localizedError('nidaq:ni:invalidManualConnectionWithAutoSync',...
                        newSource,...
                        newDestination)
                end
                
            end
        end       
    end    
    
end

