classdef (Hidden) DeviceRenamedInfo < event.EventData & daq.internal.BaseClass
    %DeviceRenamedInfo Device Information associated with a device rename event
    % Listeners on the DeviceRenamed event of the daq.HardwareInfo object will
    % receive a call to their listener function with a
    % daq.DeviceRenamedInfo object as the second/EVENTINFO parameter.
    %
    % Example:
    %
    % See also: daq.HardwareInfo.DeviceRenamed, handle.addlistener
   
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.3 $  $Date: 2010/08/07 07:25:38 $

    %% -- Public methods, properties, and events --
    % Read only properties
    properties(SetAccess=private)
        % The string ID associated with the device before it was renamed
        OldDeviceID
        
        % The daq.DeviceID object associated with the device after it was
        % renamed.
        NewDevice
    end
        
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = DeviceRenamedInfo(oldDeviceID,newDeviceInfo)
            if ~ischar(oldDeviceID)
                obj.localizedError('daq:general:deviceIDInvalid');
            end
            obj.OldDeviceID = oldDeviceID;

            if ~isscalar(newDeviceInfo) || ~isa(newDeviceInfo,'daq.DeviceInfo')
                obj.localizedError('daq:general:deviceInfoInvalid');
            end
            obj.NewDevice = newDeviceInfo;
        end
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end
end

