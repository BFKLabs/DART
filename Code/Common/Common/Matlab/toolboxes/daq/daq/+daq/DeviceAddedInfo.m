classdef (Hidden) DeviceAddedInfo < event.EventData & daq.internal.BaseClass
    %DeviceAddedInfo Device Information associated with a deviceInfo add event
    % Listeners on the DeviceAddedInfo event of the daq.HardwareInfo object will
    % receive a call to their listener function with a
    % daq.DeviceAddedInfo object as the second/EVENTINFO parameter.
    %
    % Example:
    %
    % See also: daq.HardwareInfo.DeviceAdded, handle.addlistener
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.3 $  $Date: 2010/08/07 07:25:34 $
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties(SetAccess=private)
        Device
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = DeviceAddedInfo(deviceInfo)
            if ~isscalar(deviceInfo) || ~isa(deviceInfo,'daq.DeviceInfo')
                obj.localizedError('daq:general:deviceInfoInvalid');
            end
            obj.Device = deviceInfo;
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

