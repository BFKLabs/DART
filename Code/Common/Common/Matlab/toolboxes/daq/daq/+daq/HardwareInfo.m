classdef (Hidden, Sealed) HardwareInfo < daq.internal.BaseClass & daq.internal.UserDeleteDisabled
    %HardwareInfo Hardware Information from the Data Acquisition toolbox
    %    On initial instantiation, adaptor and device discovery occurs.
    %    Call daq.HardwareInfo.getInstance() to get information.
    %
    % See also: daq.getVendors, daq.getDevices
    
    % Copyright 2009-2010 The MathWorks, Inc.
    % $Revision: 1.1.6.10.2.1 $  $Date: 2014/02/11 04:16:41 $
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        %Devices Array of all supported devices
        Devices
        
        %KnownVendors Array of all known vendors, regardless of
        %whether they have functional hardware installed.
        KnownVendors
    end
    
    % Events
    events
        % DeviceAdd is fired when a device is added to the system.  The
        % listener will receive a daq.DeviceAdded event data structure.
        DeviceAdded
        
        % DeviceRemoved is fired when a device is removed from the system.  The
        % listener will receive a daq.DeviceRemoved event data structure.
        DeviceRemoved
        
        % DeviceRenamed is fired when a device is renamed in the system.  The
        % listener will receive a daq.DeviceRenamed event data structure.
        DeviceRenamed
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Access=private)
        function obj = HardwareInfo(varargin)
            % Initialize the option cache, and pass in the requested
            % options
            daq.internal.getOptions(varargin{:});
            
            % Initialize properties
            obj.Devices = daq.DeviceInfo.empty;
            obj.KnownVendors = daq.VendorInfo.empty;
            
            % Check the current platform, and see if it is supported.
            % {'all'} disables this check
            if ~strcmp(daq.internal.getOptions().SupportedPlatforms{1},'all') &&...
                ~ismember(computer('arch'),daq.internal.getOptions().SupportedPlatforms)
                obj.localizedError('daq:general:platformNotSupported',...
                    computer('arch'),...
                    obj.renderCellArrayOfStringsToString(daq.internal.getOptions().SupportedPlatforms,','))
            end
            
            obj.findAndRegisterVendors();
        end
    end
    
    % Destructor
    methods (Access = protected)
        function delete(obj)
            %delete Delete the hardware information
            obj.Devices = [];
            obj.KnownVendors = [];
        end
    end
    
    % Hidden public methods, which are used as friend methods
    methods(Hidden)
        function addDevice(obj,deviceInfo)
            %addDevice Add a device to the list of operational devices.
            %addDevice(deviceInfo) Adds the deviceInfo device to the list of
            %Devices.
            
            % Check that the vendor passed us a daq.DeviceInfo object
            if ~isa(deviceInfo,'daq.DeviceInfo')
                obj.localizedError('daq:general:deviceInfoRequired')
            end
            
            % Check that the device has a unique name
            if ~isempty(obj.Devices.find(deviceInfo.Vendor.ID,deviceInfo.ID))
                obj.localizedError('daq:general:duplicateDeviceID',...
                    deviceInfo.Vendor.ID,deviceInfo.ID)
            end
            
            obj.Devices(end+1) = deviceInfo;
            
            % Notify listeners of device add
            notify(obj,'DeviceAdded',daq.DeviceAddedInfo(deviceInfo))
        end
        
        function removeDevice(obj,deviceInfo)
            %removeDevice Remove a device from the list of operational devices.
            %removeDevice(deviceInfo) Removes the device specified by
            %deviceInfo from the list of Devices.
            
            % Check that the vendor passed us a daq.DeviceInfo object
            if ~isa(deviceInfo,'daq.DeviceInfo')
                obj.localizedError('daq:general:deviceInfoRequired')
            end
            
            index = obj.Devices.find(deviceInfo.Vendor.ID,deviceInfo.ID);
            if isempty(index)
                if daq.internal.getOptions().FullDebug
                    obj.localizedError('daq:general:attemptedRemovalOfNonexistentDevice',deviceInfo.ID)
                end
                return
            end
            
            vendor = obj.Devices(index).Vendor;
            deviceID = obj.Devices(index).ID;
            obj.Devices(index) = [];
            
            % Notify listeners of device add
            notify(obj,'DeviceRemoved',daq.DeviceRemovedInfo(vendor,deviceID))
        end
        
        function renameDevice(obj,oldDeviceInfo,newDeviceInfo)
            %renameDevice Renames a device in the list of operational devices.
            %renameDevice(oldDeviceInfo, newDeviceInfo) Replaces the device
            %specified by oldDeviceInfo with the device described by
            %newDeviceInfo in the list of Devices.
            
            % Check that the vendor passed us a daq.DeviceInfo object
            if ~isa(oldDeviceInfo,'daq.DeviceInfo') ||...
                    ~isa(newDeviceInfo,'daq.DeviceInfo')
                obj.localizedError('daq:general:deviceInfoRequired')
            end
            
            index = obj.Devices.find(oldDeviceInfo.Vendor.ID,oldDeviceInfo.ID);
            if isempty(index)
                if daq.internal.getOptions().FullDebug
                    obj.localizedError('daq:general:attemptedRenameOfNonexistentDevice',...
                        oldDeviceInfo.ID,newDeviceInfo.ID)
                end
                return
            end
            
            if ~strcmp(oldDeviceInfo.UniqueHardwareID,...
                    newDeviceInfo.UniqueHardwareID)
                    obj.localizedError('daq:general:renameDeviceMustHaveSameUniqueHardwareID',...
                        oldDeviceInfo.ID,newDeviceInfo.ID)
            end
            
            oldDeviceID = obj.Devices(index).ID;
            obj.Devices(index) = newDeviceInfo;
            
            % Notify listeners of device add
            notify(obj,'DeviceRenamed',daq.DeviceRenamedInfo(oldDeviceID,newDeviceInfo))
        end
    end
    
    % Hidden static methods, which are used as friend methods
    methods(Hidden,Static)
        function value = getInstance(varargin)
            persistent Instance;
            
            % The Instance variable can become invalid when the underlying
            % daq.HardwareInfo object gets deleted as part of a daq.reset.
            % Thus, we check if it is empty AND if it is valid.
            if isempty(Instance) || ~isvalid(Instance)
                % For development purposes, it is possible to call
                % getInstance immediately after a daq.reset (or initial
                % startup) with a set of PV pair options.  See the
                % constructor for details.
                Instance = daq.HardwareInfo(varargin{:});
            elseif nargin ~= 0
                % If getInstance is called with parameters anytime later,
                % we throw a warning indicating that those options have
                % been ignored.
                warning(message('daq:general:cannotAcceptParams'));
            end
            value = Instance;
        end
    end
    
    % Private properties
    properties (GetAccess = private,SetAccess = private)
    end

    % Internal constants
    properties(Constant, GetAccess = private)
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
    
    % Private methods
    methods (Access = private)
        function findAndRegisterVendors(obj)
            %findAndRegisterVendors Search for data acquisition vendor adaptors.
            %Searches all sub packages of daq to locate subclasses of
            %daq.Vendor that are candidates for registration, and registers
            %them.
            
            if daq.internal.getOptions().UnitTestMode
                % This is executed when we are running under unit tests --
                % it allows us to ONLY load the test vendors.  Since the
                % test vendors are not normally shipped, they will not
                % appear in the list of vendors when we ship normally.
                knownVendorList = internal.findSubClasses('daq','daq.test.hVendorInfoForTests',true);
            elseif daq.internal.getOptions().DemoMode
                % This is executed when we are running in demo mode --
                % it allows us to ONLY load the demo vendors.  Since the
                % demo vendors are not normally shipped, they will not
                % appear in the list of vendors when we ship normally.
                knownVendorList = internal.findSubClasses('daq','daq.VendorInfoForDemos',true);
            else
                knownVendorList = internal.findSubClasses('daq','daq.VendorInfo',true);              
                knownVendorList = knownVendorList(~cellfun(@(v) (v.Abstract), knownVendorList));
            end
            
            % If the 'NoVendors' mode is set, the system pretends there are no vendors.
            if daq.internal.getOptions().UnitTestMode && daq.internal.getOptions().NoVendors
                return
            end
            
            for iVendor = 1:numel(knownVendorList)
                try
                    obj.addVendor(knownVendorList{iVendor}.Name);
                catch e
                    % Normally, we ignore any failed load, but if the
                    % 'FullDebug' option is set, we don't.
                    if daq.internal.getOptions().FullDebug
                        % Don't error (or later adaptors won't load), but
                        % print the error report
                        fprintf('===========Adaptor %s could not load==============\n',...
                            knownVendorList{iVendor}.Name)
                        fprintf('%s\n',e.getReport())
                        fprintf('========================================================\n')
                    end
                end
            end
        end
        
        function addVendor(obj,vendorInfoClassName)
            %addVendor Add a vendor to the list of known vendors.
            %addVendor(VENDORINFOCLASSNAME) Instantiates the VendorInfo
            %subclass specified by string VENDORINFOCLASSNAME, and adds it
            %to the list of KnownVendors, and calls
            %VendorInfo.registerDevices with a reference to the addDevice
            %function so that devices can be registered.
            
            % Instantiate the vendor information class that was found
            vendor = eval([vendorInfoClassName '()']);
            
            % Check that the vendor has a unique name
            if ~isempty(obj.KnownVendors.find(vendor.ID))
                obj.localizedError('daq:general:duplicateVendorID',vendor.ID)
            end
            
            % If the 'NoDevices' mode is set, the system pretends there are
            % no devices on each vendor.
            if daq.internal.getOptions().UnitTestMode && daq.internal.getOptions().NoDevices
                obj.KnownVendors(end+1) = vendor;
                return
            end
            
            % Always add the vendor, whether operational or not
            obj.KnownVendors(end+1) = vendor;

            % Only try to register the devices if the vendor is operational
            if vendor.IsOperational
                vendor.registerDevices(@obj.addDevice);
            end
            
        end
    end
end
