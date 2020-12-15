classdef (Hidden) Connection < daq.Connection
    %% -- Protected and private members of the class --
    
    %   Copyright 2011-2012 The MathWorks, Inc.
    
    % Non public-constructor
    methods(Hidden)
        function obj = Connection(session,source,destination,type)
            obj@daq.Connection(session,source,destination,type);
        end
    end
    
    methods(Access = public, Hidden)
        
        % Get source device for the connection
        function sourceDevice = getSourceDevice(obj)
            sourceDevice = obj.getDevice(obj.Source);
        end
        
        % Get destination device for the connection
        function destinationDevice = getDestinationDevice(obj)
            destinationDevice = obj.getDevice(obj.Destination);
        end
        
        function result = getConnectionDescriptionHook(obj)
            
            % Get devices
            sourceDevice = obj.getSourceDevice();
            destinationDevice = obj.getDestinationDevice();
            
            % Get terminals
            sourceTerminal = daq.DeviceTerminalPair.getTerminal(obj.Source);
            destinationTerminal = daq.DeviceTerminalPair.getTerminal(obj.Destination);
            
            % Display the connection type full name
            connectionTypeFullName = obj.getConnectionFullName();
            result = [connectionTypeFullName ' '];
            
            % If the destination is external, the display should look like
            %
            %  ' for '-' will available at terminal '-' for
            %  external use.'
            %
            if strcmpi(destinationDevice,daq.SyncManager.ExternalDevice)
                result = [ result obj.getLocalizedText('nidaq:ni:externalDestinationVerbalDisp',sourceDevice,sourceTerminal)];
                result = [ result '\n' ];
                return;
            end
            
            % Display the source
            if strcmpi(sourceDevice,daq.SyncManager.ExternalDevice)
                % If the source is external, the display should look like
                %
                %  'is provided externally'
                %
                result = [ result obj.getLocalizedText('nidaq:ni:externalSourceVerbalDisp')];
            else
                % If the source & destination are both not external,
                % the display should look like -
                %
                %  'is provided by '' at '' and will be
                %  received'
                %
                result = [ result obj.getLocalizedText('nidaq:ni:sourceVerbalDisp',sourceDevice,sourceTerminal)];
            end
            
            % Display the destination
            result = [ result  ' ' obj.getLocalizedText('nidaq:ni:connectionDestinationVerbalDisp',destinationDevice,destinationTerminal) '.'];
            result = [ result '\n'];
        end
    end
    
    methods( Access = private )
        function result = getDevice(obj,deviceTerminalPair) %#ok<INUSL>
            
            deviceID = daq.DeviceTerminalPair.getDevice(deviceTerminalPair);
            
            % Convert deviceID to device

            % g873066,873097,885613: Fixed LXE incompatibility warnings
            HardwareInfo = daq.HardwareInfo.getInstance(); 
            allAvailableDevices = HardwareInfo.Devices;
            device = allAvailableDevices.locate('ni',deviceID);
            
            % g835021: To add support for accessing module PFIs for clock
            % and trigger connections, the real source device for a module
            % PFI connection is the chassis itself and not the module.
            % If it is a compactDAQ module, use the chassis name instead of
            % the device name.
            if isa(device,'daq.ni.CompactDAQModule')
                result = device.ChassisName;
            else
                result = deviceID;
            end
        end
    end
end

