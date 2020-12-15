classdef (Hidden) VendorInfo < daq.internal.BaseClass & daq.internal.UserDeleteDisabled
    %VendorInfo Information about a data acquisition vendor
    %    This class is subclassed by adaptors to provide
    %additional information about a particular vendor
    %implementation.  There will be a single instance of this
    %class for each vendor adaptor.  Vendors may choose to add
    %custom properties and methods.
    
    % Copyright 2009-2013 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = VendorInfo(id, fullName, adaptorVersion, driverVersion, driverPath)
            %VendorInfo Information about a data acquisition vendor
            % VendorInfo(ID, FULLNAME, ADAPTORVERSION, DRIVERVERSION, DRIVERPATH) 
            % contains basic vendor information, such as a short unique
            % string ID that is used by daq.createSession, the string
            % FULLNAME which is used to describe the vendor in full, the
            % string ADAPTORVERSION which contains the version number of
            % this set of vendor specific classes, the string DRIVERVERSION
            % which contains the version number of the vendor driver, and
            % the string DRIVERPATH that indicates the location on disk of
            % the primary driver file in use by the vendor adaptor. 
            assert(ischar(id) && ...
                ischar(fullName) && ...
                (isnumeric(adaptorVersion) || ischar(adaptorVersion)) && ...
                (isnumeric(driverVersion) || ischar(driverVersion)) && ...
                ischar(driverPath))
            
            obj.ID = id;
            obj.FullName = fullName;
            obj.AdaptorVersion = adaptorVersion;
            obj.DriverVersion = driverVersion;
            obj.DriverPath = driverPath;
            obj.IsOperational = false; % Vendors must set this true
        end
    end

    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        %ID The vendor identification string.
        ID
        
        %FullName The full name of vendor.
        FullName
        
        %AdaptorVersion Version info about the vendor's adaptor.
        AdaptorVersion
        
        %DriverVersion Version info about the vendor's driver.
        DriverVersion
    end
    
    % Read only properties that can be altered by a subclass
    properties (SetAccess = protected)
        %IsOperational True if the vendors adaptor is operational.
        IsOperational
    end
    
    % G938399: Hidden methods
    methods (Hidden) 
        function addlistener(~)
        end
    end
    
    % Sealed hidden methods
    methods(Sealed, Hidden)
        % G938392: Undocumented method, to be removed in a later release.
        function summaryText = getOperationalSummary(obj)
            %getOperationalSummary Summarize problems preventing operation.
            %summaryText = getOperationalSummary() Returns a string
            %providing diagnostic information in the event that
            %IsOperational is false. If true, returns "Operational".
            
            if ~isscalar(obj)
                obj.localizedError('daq:VendorInfo:getOperationalSummaryRequiresScalar')
            end
            
            if obj.IsOperational
                summaryText = obj.getLocalizedText('daq:general:operationalText');
            else
                summaryText = getOperationalSummaryImpl(obj);
            end
        end
    end
    
    % Sealed methods
    methods(Sealed)
        function disp(obj)
            if any(~isvalid(obj))
                % Invalid object: use default behavior of handle class
                obj.disp@handle
                return
            end
            
            % In some contexts, such as publishing, you cannot use
            % hyperlinks.  If hotlinks is true, then you can.
            hotlinks = feature('hotlinks');
            
            if isempty(obj)
                % Empty object: give information appropriate to no vendors
                obj.localized_fprintf('daq:VendorInfo:noVendorsAvailable');
                if hotlinks
                    obj.localized_fprintf('daq:VendorInfo:noVendorsTroubleshootingHyperlink');
                    obj.localized_fprintf('daq:general:downloadAdditionalVendors');
                    fprintf('\n');
                end
                fprintf('\n')
                obj.dispFooter(class(obj),inputname(1),feature('HotLinks'));
                return
            end
            
            if numel(obj) == 1
                % Single object -- do detailed display

                % Title
                obj.localized_fprintf('daq:VendorInfo:dispTitle',...
                    obj.FullName);
                fprintf('\n')
                get(obj)
                
                if obj.IsOperational
                    % Check to see if the Vendor implementation has defined
                    % additional information to append to the display
                    suffixText = getSingleDispSuffixHook(obj);
                    if ~isempty(suffixText)
                        fprintf('\n')
                        fprintf(suffixText);
                    end
                else
                    %Add additional information if IsOperational is false
                    fprintf('\n')                   
                    obj.localizedWarning('daq:VendorInfo:diagnosticIntro',obj.getOperationalSummary());
                end
                
            else
                % It's a vector of objects:  Show as table
                obj.localized_fprintf('daq:VendorInfo:dispHeader',num2str(numel(obj)))
                fprintf('\n')
                table = internal.DispTable();
                table.addColumn(obj.getLocalizedText('daq:VendorInfo:dispIndexColHeader'));
                table.addColumn(obj.getLocalizedText('daq:VendorInfo:dispIDColHeader'));
                table.addColumn(obj.getLocalizedText('daq:VendorInfo:dispOperationalColHeader'));
                table.addColumn(obj.getLocalizedText('daq:VendorInfo:dispCommentColHeader'));
                for iObj=1:numel(obj)
                    if obj(iObj).IsOperational || ~hotlinks
                        comment = obj(iObj).FullName;
                    else
                        comment = internal.DispTable.matlabLink(...
                            obj.getLocalizedText('daq:VendorInfo:clickHereForMoreInfoHyperlink'),...
                            sprintf('daq.getVendors().locate(''%s'').getOperationalSummary()',...
                                        obj(iObj).ID));
                    end
                    table.addRow(iObj,obj(iObj).ID,obj(iObj).IsOperational,comment);
                end
                table.disp
            end
            fprintf('\n')
            obj.dispFooter(class(obj),inputname(1),hotlinks);
            
            if hotlinks
               obj.localized_fprintf('daq:general:downloadAdditionalVendors'); 
               fprintf('\n');
            end
        end
    end
    
    %% -- Protected and private members of the class --
    % Hidden read only properties
    properties (SetAccess = protected,Hidden)
        %IsVendorHidden If true, do not show this vendor in displays
        % You might set this true in order to hide an adaptor that is there
        % for backward compatibility, or is being deprecated.
        IsVendorHidden = false;
        
        %DriverPath Full file path to the vendor's driver.
        DriverPath
    end

    % Hidden sealed methods, which are used as friend methods
    methods (Sealed, Hidden)
        function vendor = locate(obj, vendorID)
            % Locates a vendor by ID from an array of VendorInfo objects
            index = obj.find(vendorID);
            if ~any(index)
                % If not found, return empty
                vendor = [];
            else
                vendor = obj(index);
            end
        end
        
        function index = find(obj, vendorID)
            % Returns the index into the vendor list based on the ID from an array of VendorInfo objects
            matches = strcmp(vendorID,{obj.ID});
            index = 1:numel(matches);
            index = index(matches);
        end
        
        function registerDevices(obj,fcnAddDevice)
            %registerDevices Called to register devices with daq.HardwareInfo
            
            % During initial registration of devices, we need to store the
            % function handle to daq.HardwareInfo.addDevice as the
            % HardwareInfo object has not yet completed instantiation, and
            % so we cannot call getInstance on it.
            obj.FcnAddDevice = fcnAddDevice;
            obj.registerDevicesImpl();
        end
    end
    
    % Protected methods requiring implementation by a subclass
    methods (Access = protected)
        % Effectively, these are abstract methods.  However, we want
        % daq.VendorInfo.empty to work, so there has to be some
        % implementation.
        
        %getOperationalSummaryImpl Subclasses MUST override to return a
        %string with diagnostic information associated with their
        %adaptor, installation, and hardware.  The result should
        %provide a call to action for the user.
        function summaryText = getOperationalSummaryImpl(obj) %#ok<STOUT>
            % Default implementation throws a "not implemented" error.
            obj.throwNotImplementedError()
        end
        
        %registerDevicesImpl Subclasses MUST override with code to register
        %their devices with daq.HardwareInfo by calling addDevice() for
        %each device
        function registerDevicesImpl(obj)
            % Default implementation throws a "not implemented" error.
            obj.throwNotImplementedError()
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function suffixText = getSingleDispSuffixHook(~)
            %getSingleDispSuffixHook Subclasses override to customize disp
            %suffixText = getSingleDispSuffixHook() Optional override by
            %VendorInfo subclasses to allow them to append custom
            %information to the end of the disp of a single VendorInfo object.
            
            suffixText = '';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function registerSessionFactory(obj,vendorSessionFactory)
            %registerSessionFactory Subclasses call to register their
            %session factories.
            %registerSessionFactory(SESSIONCLASSNAME) Used by
            %VendorInfo subclasses to register the session class
            %associated with the vendor.  This implemented using a default
            %factory.  For most cases, this the appropriate choice.
            %
            %registerSessionFactory(VENDORSESSIONFACTORY) Used by
            %sophisticated VendorInfo subclasses to register custom
            %SessionFactory classes derived from
            %daq.internal.SessionFactory.  This allows them to return
            %different daq.Session objects based on parameters or
            %conditions.
            
            if ischar(vendorSessionFactory)
                vendorSessionFactory = daq.internal.SessionFactory(obj,vendorSessionFactory);
            end
            if ~isa(vendorSessionFactory,'daq.internal.SessionFactory')
                obj.localizedError('daq:VendorInfo:invalidSessionFactory');
            end
            SessionManager = daq.internal.SessionManager.getInstance;
            SessionManager.registerSessionFactory(obj.ID,vendorSessionFactory);
        end
        
        function addDevice(obj,deviceInfo)
            % Add a device to the Data Acquisition Toolbox, either
            % during registerDevicesImpl, or in response to a device plug
            % in event.
            %
            % addDevice(DEVICEINFO) adds the described by DEVICEINFO, which
            % is of type daq.DeviceInfo
            %
            % A successful call to addDevice will cause the
            % daq.HardwareInfo.DeviceAdded event to fire.
            
            % During initial registration of devices, we need to store the
            % function handle to daq.HardwareInfo.addDevice as the
            % HardwareInfo object has not yet completed instantiation, and
            % so we cannot call getInstance on it.
            obj.FcnAddDevice(deviceInfo);
        end
        
        function removeDevice(~,deviceInfo)
            % Remove a device from the Data Acquisition Toolbox in response
            % to a device unplug event.
            %
            % removeDevice(DEVICEINFO) removes the described by DEVICEINFO, which
            % is of type daq.DeviceInfo
            %
            % A successful call to removeDevice will cause the
            % daq.HardwareInfo.DeviceRemoved event to fire.
            daq.HardwareInfo.getInstance.removeDevice(deviceInfo);
        end
        
        function renameDevice(~,oldDeviceInfo,newDeviceInfo)
            % Rename a device in the Data Acquisition Toolbox in response
            % to a device rename event.
            %
            % renameDevice(OLDDEVICEINFO,NEWDEVICEINFO) replaces the device
            % described by OLDDEVICEINFO with the device described by
            % NEWDEVICEINFO, which are both of type daq.DeviceInfo.
            % OLDDEVICEINFO and NEWDEVICEINFO must have the same value for
            % their UniqueHardwareID property
            %
            % A successful call to renameDevice will cause the
            % daq.HardwareInfo.DeviceRenamed event to fire.
            daq.HardwareInfo.getInstance.renameDevice(oldDeviceInfo,newDeviceInfo);
        end
    end
   
    % Private properties
    properties (SetAccess = private,GetAccess = private)
        % FcnAddDevice Store the function handle to
        % HardwareInfo.addDevice during initial registration.
        % During initial registration of devices, we need to store the
        % function handle to daq.HardwareInfo.addDevice as the
        % HardwareInfo object has not yet completed instantiation, and
        % so we cannot call getInstance on it.
        FcnAddDevice
    end

    % Protected methods this class is required to implement
    methods (Sealed, Access = protected)
       
        function result = getDispHook(obj)
            %getDispHook() returns a short string to be used in the display of this object in a getdisp operation.
            result = obj.FullName;
        end
        
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end
end
