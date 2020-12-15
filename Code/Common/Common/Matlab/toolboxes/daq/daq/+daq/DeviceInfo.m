classdef (Hidden) DeviceInfo < daq.internal.BaseClass & daq.internal.UserDeleteDisabled
    %DeviceInfo Information about a data acquisition device
    %    This class is subclassed by adaptors to provide
    %additional information about a particular device
    %implementation.  There will be a single instance of this
    %class for each vendor adaptor.  They may choose to add
    %custom properties and methods.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        %Vendor Information about the vendor associated with this
        %device.
        Vendor
        
        %ID A unique string identifying the device that is assigned
        %by the vendor.
        ID
        
        %Model A string identifying the model number of the device.
        Model
        
        %Subsystems Contains one or more objects representing
        %information about the subsystems of the device.
        Subsystems
    end
    
    % Read only properties that can be altered by a subclass
    properties (SetAccess = protected)
        %Description A description of the device, of the form
        %"Vendor.FullName Model"
        Description
        
        %RecognizedDevice A boolean indicating whether the adaptor
        %recognized this device.  If false, a
        %warning will be generated when this device is used.
        RecognizedDevice
    end
    
    % Sealed methods
    methods(Sealed)
       function disp(obj)
            %disp display device information
            
            % In some contexts, such as publishing, you cannot use
            % hyperlinks.  If hotlinks is true, then you can.
            hotlinks = feature('hotlinks');
            
            if any(~isvalid(obj))
                % Invalid object: use default behavior of handle class
                obj.disp@handle
                return
            end
            
            if isempty(obj)
                % Empty object: give information appropriate to no vendors
                obj.localized_fprintf('daq:DeviceInfo:noDevicesAvailable');
                if hotlinks
                    obj.localized_fprintf('daq:DeviceInfo:noDevicesVendorListHyperlink');
                    obj.localized_fprintf('daq:DeviceInfo:noDevicesTroubleshootingHyperlink');
                    fprintf('\n')
                end
                return
            end
            
            if numel(obj) == 1
                description = obj.Description;
                if ~obj.RecognizedDevice
                    % Put an asterisk in front of any unrecognized
                    % device
                    description = [description ' *']; 
                end                
                fprintf('%s: %s (Device ID: ''%s'')\n',...
                    obj.Vendor.ID,...
                    description,...
                    obj.ID);
                % Display the subsystem information for this device,
                % indented 3 spaces
                for iSubsystem = 1:numel(obj.Subsystems)
                    fprintf(obj.indentText(obj.Subsystems(iSubsystem).getDisplayText(),obj.StandardIndent));
                    fprintf('\n');
                end
                
                % If device is unrecognized devices, add the footnote
                if (~obj.RecognizedDevice)
                    fprintf('\n');                    
                    obj.localized_fprintf('daq:DeviceInfo:dispNotSupportedFootnote');                    
                end
                
                % Check to see if the Vendor implementation has defined
                % additional information to append to the display
                suffixText = getSingleDispSuffixHook(obj);
                if ~isempty(suffixText)
                    fprintf(suffixText);
                    fprintf('\n')
                end
                
                % Add standard footer.  Since it is likely that the disp is
                % being done on "ans," and we don't want these hyperlinks
                % to go bad in the command window (since ans will likely
                % change), pass in an explicit command so that the
                % hyperlink will always work.
                fprintf('\n')
                obj.dispFooter(class(obj),...
                    sprintf('daq.getDevices().locate(''%s'',''%s'')',obj.Vendor.ID,obj.ID),...
                    hotlinks);
            else
                % It's a vector of objects:  Show as table
                obj.localized_fprintf('daq:DeviceInfo:dispHeader')
                table = internal.DispTable();
                fprintf('\n');
                table.addColumn(obj.getLocalizedText('daq:DeviceInfo:dispIndexColHeader'));
                table.addColumn(obj.getLocalizedText('daq:DeviceInfo:dispVendorColHeader'));
                table.addColumn(obj.getLocalizedText('daq:DeviceInfo:dispIDColHeader'));
                table.addColumn(obj.getLocalizedText('daq:DeviceInfo:dispDescriptionColHeader'));
                for iObj=1:numel(obj)
                    description = obj(iObj).Description;
                    if ~obj(iObj).RecognizedDevice
                        % Put an asterisk in front of any unrecognized
                        % device
                        description = ['* ' description]; %#ok<AGROW>
                    end
                    % Hyperlink the device ID
                    deviceID = internal.DispTable.matlabLink(...
                        obj(iObj).ID,...
                        sprintf('daq.getDevices().locate(''%s'',''%s'')',...
                        obj(iObj).Vendor.ID,obj(iObj).ID));
                    table.addRow(iObj,obj(iObj).Vendor.ID,deviceID,description);
                end
                table.disp
                if any(~[obj.RecognizedDevice])
                    % If there are any unrecognized devices in the list, add
                    % the footnote
                    fprintf('\n');
                    obj.localized_fprintf('daq:DeviceInfo:dispNotSupportedFootnote')
                end
            end
            fprintf('\n');
        end
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = DeviceInfo(vendor, id, model, uniqueHardwareID)
            %DeviceInfo Information about a data acquisition device
            %
            %DeviceInfo(VENDOR,ID,MODEL) Information about a data
            %acquisition supported by the VENDOR, a daq.VendorInfo object,
            %a string or numeric ID containing the vendor's identifier, a
            %string MODEL describing the model.
            %
            % Note that if ID is provided as a numeric, the toolbox will
            % convert it to a string as refer to the hardware using the
            % string version of the ID.
            %
            %DeviceInfo(...,UNIQUEHARDWAREID) The optional string
            %UNIQUEHARDWAREID provides a mechanism to track hardware
            %through plug in, unplug, and rename events, using a vendor
            %defined string.  UNIQUEHARDWAREID should uniquely identify a
            %specific piece of hardware, such as the serial number.  If the
            %vendor does not provide one, it defaults to
            %“<deviceID>-<timestamp of object creation>
            
            obj.Subsystems = daq.SubsystemInfo.empty;
            obj.RecognizedDevice = false;
            obj.HasUnrecognizedDeviceWarningBeenIssued = false;
            
            if ~(isa(vendor,'daq.VendorInfo') && ...
                    (isnumeric(id) || ischar(id)) && ...
                    ischar(model))
                obj.localizedError('daq:DeviceInfo:deviceInfoBadParam')
            end
            
            obj.Vendor = vendor;
            if isnumeric(id)
                % Numeric IDs are converted to strings
                obj.ID = num2str(id);
            else
                obj.ID = id;
            end
            
            obj.Model = model;
            
            if nargin < 4
                % If the vendor does not provide one, UniqueHardwareID
                % defaults to “<deviceID>-<timestamp of object creation>”
                obj.UniqueHardwareID = [id '-' datestr(now)];
            else
                obj.UniqueHardwareID = uniqueHardwareID;
            end
            
            % By default, the description is "<Vendor.FullName> <Model>"
            % Adaptors can override
            obj.Description = [obj.Vendor.FullName ' ' obj.Model];
        end
    end
    
    % Hidden read only properties
    properties(Hidden,SetAccess = private)
        %UniqueHardwareID Hardware is tracked using a unique, vendor
        %defined string.  This ID should uniquely identify a specific piece
        %of hardware, such as the serial number.  If the vendor does not
        %provide one, it defaults to “<deviceID>-<timestamp of
        %object creation>”
        UniqueHardwareID
    end
    
    % Hidden public sealed methods, which are used as friend methods
    methods (Sealed,Hidden)
        function device = locate(obj, vendorID, deviceID)
            % Locates a device by vendor ID and device ID from an array of
            % DeviceInfo objects.  If deviceID is empty or not supplied,
            % all devices from the vendor are returned.
            
            if(nargin < 3)
                deviceID = '';
            end
            
            index = obj.find(vendorID, deviceID);
            if ~any(index)
                % If not found, return empty
                device = [];
            else
                device = obj(index);
            end
        end
        
        function index = find(obj, vendorID, deviceID)
            % Returns the index of a device by vendor ID and device ID from
            % an array of DeviceInfo objects.  If deviceID is empty or not
            % supplied, all devices from the vendor are returned.
            
            if(nargin < 3)
                deviceID = '';
            end
            vendors = [obj.Vendor];
            
            if isempty(vendors)
                % If there's no vendor, return empty
                index = [];
                return
            end
            
            if isempty(deviceID)
                % Get all devices from the vendor
                matches = strcmp(vendorID,{vendors.ID});
            else
                % If both the vendor ID and device ID match, then it's OK.
                % Use case insensitive matching for the deviceID which is
                % typed in by the user. This will allow matching for
                % cDAQ1mod1 with the real name which has a capital M. This
                % is how NI-DAQmx and our own V2 behaves.
                % Since we only do the match case insensitive the actual
                % device ID will be in the correct case in the object.
                matches = strcmp(vendorID,{vendors.ID}) & strcmpi(deviceID,{obj.ID});
            end
            index = 1:numel(matches);
            index = index(matches);
        end
        
        function device = locateByUniqueID(obj, vendorID, uniqueID)
            % Hardware is tracked by channels using a unique, vendor
            % defined string.  This ID should uniquely identify a specific
            % piece of hardware, such as the serial number.  Locates a
            % device by vendor ID and unique ID from an array of DeviceInfo
            % objects
            
            index = obj.findByUniqueID(vendorID, uniqueID);
            if ~any(index)
                % If not found, return empty
                device = [];
            else
                device = obj(index);
            end
        end
        
        function index = findByUniqueID(obj, vendorID, uniqueID)
            % Returns the index of a device by vendor ID and unique ID from an array of DeviceInfo objects
            vendors = [obj.Vendor];
            
            if isempty(vendors)
                % If there's no vendor, return empty
                index = [];
                return
            end
            
            % If both the vendor ID and unique ID match, then it's OK.
            matches = strcmp(vendorID,{vendors.ID}) & strcmp(uniqueID,{obj.UniqueHardwareID});
            index = 1:numel(matches);
            index = index(matches);
        end
        
        function subsystem = getSubsystem(obj, subsystemType)
            % Returns the subsystem of a device using a
            % daq.internal.SubsystemType
            if ~isscalar(obj) || ~isa(subsystemType,'daq.internal.SubsystemType')
                obj.localizedError('daq:DeviceInfo:invalidParameterToGetSubsystemInfo')
            end
            
            % Locate the matching subsystem
            subsystem = obj.Subsystems([obj.Subsystems.SubsystemTypeInfo] == subsystemType);
        end
        
        function warnOnUnrecognizedDeviceAttempt(obj)
            %warnOnUnrecognizedDeviceAttempt The first time called, it warns
            %warnOnUnrecognizedDeviceAttempt() Throws a warning
            %indicating that a channel from an unrecognized device was
            %added to a Session object.  If called again, simply returns.
            
            error(nargchk(1,1,nargin,'struct'))
            
            if obj.RecognizedDevice || obj.HasUnrecognizedDeviceWarningBeenIssued
                return
            end
            obj.HasUnrecognizedDeviceWarningBeenIssued = true;
            warning(message('daq:DeviceInfo:notRecognized',obj.ID));
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function suffixText = getSingleDispSuffixHook(obj) %#ok<MANU>
            %getSingleDispSuffixImpl Subclasses override to customize disp
            %suffixText = getSingleDispSuffixImpl() Optional override by
            %DeviceInfo subclasses to allow them to append custom
            %information to the disp of a single DeviceInfo object.
            
            suffixText = '';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function addSubsystem(obj,subsystem)
            %addSubsystem Subclasses call to add a SubsystemInfo record
            %to their device.
            %ADDSUBSYSTEM(SUBSYSTEM) Used by DeviceInfo subclasses to
            %add their adaptor specific SubsystemInfo record to their
            %device.
            
            obj.Subsystems(end+1) = subsystem;
        end
    end
    
    % Private properties
    properties (GetAccess = private,SetAccess = private)
        % If the RecognizedDevice flag is false on this device, then a
        % warning will fire the first time a channel from this device is
        % added to a session.
        HasUnrecognizedDeviceWarningBeenIssued
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
