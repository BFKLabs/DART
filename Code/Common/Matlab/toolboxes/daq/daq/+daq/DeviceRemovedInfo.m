classdef (Hidden) DeviceRemovedInfo < event.EventData & daq.internal.BaseClass
    %DeviceRemovedInfo Device Information associated with a device removal event
    % Listeners on the DeviceRemoved event of the daq.HardwareInfo object will
    % receive a call to their listener function with a
    % daq.DeviceRemovedInfo object as the second/EVENTINFO parameter.
    %
    % Example:
    %
    % See also: daq.HardwareInfo.DeviceRemoved, handle.addlistener
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.3 $  $Date: 2010/08/07 07:25:37 $
    
    %% -- Public methods, properties, and events --
    
    % Read only properties
    properties(SetAccess=private)
        % The daq.VendorInfo object representing the vendor of the device
        % that was removed.
        Vendor
        
        % The ID string associated with the device that was removed.
        DeviceID
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = DeviceRemovedInfo(vendorInfo,deviceID)
            if ~isscalar(vendorInfo) || ~isa(vendorInfo,'daq.VendorInfo')
                obj.localizedError('daq:general:vendorInfoInvalid');
            end
            if ~ischar(deviceID)
                obj.localizedError('daq:general:deviceIDInvalid');
            end
            obj.Vendor = vendorInfo;
            obj.DeviceID = deviceID;
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

