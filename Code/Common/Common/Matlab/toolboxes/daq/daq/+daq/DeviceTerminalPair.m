classdef(Hidden) DeviceTerminalPair < daq.internal.BaseClass & daq.internal.UserDeleteDisabled
    %DeviceTerminalPair Summary of this class goes here
    %   Detailed explanation goes here

    %   Copyright 2011 The MathWorks, Inc.

    methods ( Access = public, Hidden, Static)
        function validateFormat(deviceTerminalPair,propertyBeingValidated)
            try
                [ device, terminal ] = daq.DeviceTerminalPair.split(deviceTerminalPair);
            catch  %#ok<CTCH>
                % Any error in trying to split the argument, should throw
                % the incorrect format error.
                % Add escape character for the error message
                deviceTerminalPair =  regexprep(deviceTerminalPair,'\\','\\\\');
                daq.internal.BaseClass.localizedError('daq:Conn:incorrectDeviceTerminalPairFormat',propertyBeingValidated,deviceTerminalPair);
            end
            
            if strcmp(device,daq.SyncManager.ExternalDevice) ~= strcmp(terminal,daq.SyncManager.ExternalDevice) 
                daq.internal.BaseClass.localizedError('daq:Conn:incorrectDeviceTerminalPairFormat',propertyBeingValidated,deviceTerminalPair);
            end
        end
        
        function device = getDevice(deviceTerminalPair)
            %getDevice  returns the device from the device terminal pair.
            % DEVICEID = daq.DeviceTerminalPair.getDevice(PAIR)
            % returns the DEVICEID of the DEVICEID\TERMINAL:  pair.
            [ device, ~ ] = daq.DeviceTerminalPair.split(deviceTerminalPair);
        end
        
        function terminal = getTerminal(deviceTerminalPair)
            %getTerminalFromDeviceTerminalPair  returns the terminal from the
            %device terminal pair. TERMINAL = getTerminal(PAIR)
            % returns the TERMINAL of the DEVICEID\TERMINAL:  pair.
            [ ~, terminal ] = daq.DeviceTerminalPair.split(deviceTerminalPair);
        end
        
        function deviceTerminalPair = reconstruct(device,terminal)
            deviceTerminalPair = [device, '/', terminal];
        end
        
        function [ device terminal ] = split(deviceTerminalPair)
            % Accept both format 'DeviceID/Terminal' or
            % 'DeviceID\Terminal'. The vendor can decide to limit this
            % flexibility (using the validateSourceArgumentHook and validateDestinationArgumentHook)
            % or correct the slash ( using getCorrectCapitalizationHook ).
            % Source and Destination arguments of type 'External' are accepted
            if strcmpi(deviceTerminalPair,'External')
                device = daq.SyncManager.ExternalDevice;
                terminal = daq.SyncManager.ExternalDevice;
                return
            end
            % Allow the first and the last character to be a '/'
            index = regexp(deviceTerminalPair,'\\|\/');
            if any(index == 1) 
                deviceTerminalPair(1) = ''; 
            end
            
            strlen = size(deviceTerminalPair,2);
            if any(index == strlen)
                deviceTerminalPair(strlen) = '';
            end
            
            split = regexp(deviceTerminalPair,'\\|\/', 'split');
            
            device = split{1};
            terminal = split{2};
            
            if size(split,2) ~= 2 && ...
                    (isempty(device) || ...
                    isempty(terminal))                
                daq.internal.BaseClass.localizedError('daq:Conn:incorrectDeviceTerminalPairFormat',...
                    '',...
                    '');
            end
            
            
        end
        
    end
end

