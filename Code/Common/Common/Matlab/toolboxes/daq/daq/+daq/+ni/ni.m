classdef (Hidden) ni < daq.VendorInfo
    %ni demonstration adaptor for National Instruments hardware
    %
    %    This class represents hardware by National Instruments.  This
    %    version is intended for use by the build system to generate demos
    %    of the Data Acquisition Toolbox.
    %
    %    This should not be shipped to customers.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    methods
        function obj = ni()
            % Set defaults for operational status
            isOperational = true;
            operationalSummary = 'Operational';
            
            % Minimum acceptable version of NI-DAQmx (major.minor) -- this
            % cannot be a object constant, because we cannot access the
            % object until after the base class is instantiated
            minimumAcceptableDriverVersion = 9.1;
            driverVersionString = 'unknown';
            
            try
                % Try to load the mex file
                mexNIDAQmx()
            catch e
                isOperational = false;
                operationalSummary = daq.ni.ni.diagnoseMexLoadingProblem(e, minimumAcceptableDriverVersion);
            end
            
            if isOperational
                % Get the major version number
                [status,majorVersion] = daq.ni.NIDAQmx.DAQmxGetSysNIDAQMajorVersion(uint32(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                % Get the minor version number
                [status,minorVersion] = daq.ni.NIDAQmx.DAQmxGetSysNIDAQMinorVersion(uint32(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                if double(majorVersion) + (double(minorVersion) * 0.1) < minimumAcceptableDriverVersion
                    % Give error if below minimum version
                    isOperational = false;
                    % We're in the constructor, so we have to access the
                    % message catalog directly
                    operationalSummary = getString(message('nidaq:ni:doesNotMeetMinimumVersion',num2str(minimumAcceptableDriverVersion)));
                end
                
                try
                    % Try to get the update number (the "1" in 9.0.1)
                    [status,updateVersion] = daq.ni.NIDAQmx.DAQmxGetSysNIDAQUpdateVersion(uint32(0));
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    driverVersionString = sprintf('%d.%d.%d NI-DAQmx',majorVersion,minorVersion,updateVersion);
                catch e
                    if strcmp(e.identifier,'MATLAB:subscripting:classHasNoPropertyOrMethod')
                        % DAQmxGetSysNIDAQUpdateVersion not implemented
                        % just give major.minor version
                        driverVersionString = sprintf('%d.%d NI-DAQmx',majorVersion,minorVersion);
                    else
                        rethrow(e)
                    end
                end
            end
            
            obj@daq.VendorInfo('ni',...             % id
                'National Instruments',...          % fullName
                getAdaptorVersion(),...             % adaptorVersion
                driverVersionString,...             % driverVersion
                daq.ni.ni.getNIDAQmxDriverPath);    % driverPath
            obj.IsOperational = isOperational;
            obj.OperationalSummary = operationalSummary;

            % Try loading the message catalog
            obj.IsCatalogLoaded = 0;
            m = message('nidaq:ni:unknownDevice', 'test');
            try
                m.getString();
                obj.IsCatalogLoaded = 1;
            catch
                testSPPKGRootDirs = {};
                try
                    package = hwconnectinstaller.PackageInstaller.getSpPkgInfo('NI-DAQmx');
                    if ~isempty(package)
                        testSPPKGRootDirs = [testSPPKGRootDirs cellstr(package.RootDir)];
                    end
                catch
                    % G1009950: Ignore missing hwconnectinstaller in
                    % deployed applications
                end
                
                testSPPKGRootDirs = [testSPPKGRootDirs, cellstr(fullfile(mfilename('fullpath'), '..\..\..'))'];

                for idx = 1:numel(testSPPKGRootDirs)
                    [~] = registerrealtimecataloglocation(testSPPKGRootDirs{idx});
                    try
                        m.getString();
                        obj.IsCatalogLoaded = 1;
                        break;
                    catch
                    end
                end
            end
        end
    end
    
    % Private properties
    properties (GetAccess = private,SetAccess = private)
        OperationalSummary % Summary of the operational status of the adaptor
    end
    
    properties (GetAccess = public, SetAccess = private, Hidden)
        IsCatalogLoaded
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function registerDevicesImpl(obj)
            %registerDevicesImpl Subclasses override with code to register
            %their devices with daq.HardwareInfo by invoking the
            %addDevice(daq.DeviceInfo) method on the superclass.
            
            % Query for device names.  Get the needed buffer size.
            [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetSysDevNames(' ', uint32(0));
            [status,deviceNames] = daq.ni.NIDAQmx.DAQmxGetSysDevNames(blanks(bufferSize), uint32(bufferSize));
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            if ~isempty(deviceNames) % G667505:  Need to handle case where there are no devices.
                % Parse the comma separated list into a cell array of strings.
                devices = textscan(deviceNames,'%s','Delimiter',',');
                
                % Classify and add all the devices found
                cellfun(@classifyAndAddDevice,devices{1})
            end
            
            % Register the session class for ni
            obj.registerSessionFactory('daq.ni.Session');
            
            function classifyAndAddDevice(deviceName)
                % Called on each device reported by DAQmxGetSysDevNames
                [status,productCategory] = daq.ni.NIDAQmx.DAQmxGetDevProductCategory(deviceName,int32(0));
                if status ~= daq.ni.NIDAQmx.DAQmxSuccess
                    % If we can't get the product category, skip it
                    return
                end
                
                % Get the device type/model
                [bufferSize,~] = daq.ni.NIDAQmx.DAQmxGetDevProductType(deviceName,' ',uint32(0));
                [status,devProductType] = daq.ni.NIDAQmx.DAQmxGetDevProductType(deviceName,blanks(bufferSize),uint32(bufferSize));
                if status ~= daq.ni.NIDAQmx.DAQmxSuccess
                    % If we can't get the product category, skip it
                    return
                end
                
                % Create device specializations for specific devices. These
                % are special case devices which report some incorrect
                % parameters.These parameters are hard-coded from
                % data-sheet in these device specialization.
                switch devProductType
                    case {'USB-9219'}
                        % USB 9219 reports incorrect rates for Thermocouple
                        % type channel.
                        try
                            obj.addDevice(daq.ni.DeviceSpecializations.USB9219(obj,deviceName));
                            return;
                        catch e
                            obj.processUnknownDeviceException(...
                                e,...
                                deviceName,...
                                productCategory);
                        end                        
                    case {'USB-4431'}
                        % USB 4431 has discrete output rates. This property
                        % is not query-able from NI.
                        try
                            obj.addDevice(daq.ni.DeviceSpecializations.USB4431(obj,deviceName));
                            return;
                        catch e
                            obj.processUnknownDeviceException(...
                                e,...
                                deviceName,...
                                productCategory);
                        end
                end
                
                switch productCategory
                    case daq.ni.NIDAQmx.DAQmx_Val_CSeriesModule
                        % Create a CompactDAQModule object for each module
                        % found.
                        try
                            obj.addDevice(daq.ni.CompactDAQModule(obj,deviceName));
                        catch e
                            obj.processUnknownDeviceException(...
                                e,...
                                deviceName,...
                                productCategory);
                            
                        end
                        
                    case daq.ni.NIDAQmx.DAQmx_Val_CompactDAQChassis
                        % We explicitly skip chassis
                        
                    case {daq.ni.NIDAQmx.DAQmx_Val_DigitalIO,...
                        daq.ni.NIDAQmx.DAQmx_Val_MSeriesDAQ,...
                        daq.ni.NIDAQmx.DAQmx_Val_ESeriesDAQ,...
                    	daq.ni.NIDAQmx.DAQmx_Val_SSeriesDAQ,...
                    	daq.ni.NIDAQmx.DAQmx_Val_BSeriesDAQ,...
                    	daq.ni.NIDAQmx.DAQmx_Val_AOSeries,...
                    	daq.ni.NIDAQmx.DAQmx_Val_USBDAQ,...
                        daq.ni.NIDAQmx.DAQmx_Val_XSeriesDAQ,...
                        daq.ni.NIDAQmx.DAQmx_Val_NIELVIS,...
                        daq.ni.NIDAQmx.DAQmx_Val_SCSeriesDAQ,...
                        daq.ni.NIDAQmx.DAQmx_Val_TIOSeries,...
                        daq.ni.NIDAQmx.DAQmx_Val_NetworkDAQ,...
                        daq.ni.NIDAQmx.DAQmx_Val_SCExpress }

                        if daq.internal.getOptions().CompactDAQOnly
                            % We only return CompactDAQ devices
                            return
                        end
                        try
                            % Check if the device belongs to a PXI chassis
                            [status, ~] = daq.ni.NIDAQmx.DAQmxGetDevPXIChassisNum(...
                                deviceName,...
                                uint32(0));
                            if status == daq.ni.NIDAQmx.DAQmxSuccess
                                % Create a PXI module device information record for
                                % these devices
                                obj.addDevice(daq.ni.PXIModule(obj,deviceName));
                            else
                                % Create a generic NI device information record for
                                % these devices                                
                                obj.addDevice(daq.ni.DeviceInfo(obj,deviceName));
                            end
                        catch e
                            if strcmp(e.identifier, 'nidaq:ni:err201039')
                                % G660439: Ignore USB Firmware Loader
                                % Devices
                                return
                            end
                            obj.processUnknownDeviceException(...
                                e,...
                                deviceName,...
                                productCategory);
                        end
                   case daq.ni.NIDAQmx.DAQmx_Val_DynamicSignalAcquisition
                         try
                            % Check if the device belongs to a PXI chassis
                            [status, ~] = daq.ni.NIDAQmx.DAQmxGetDevPXIChassisNum(...
                                deviceName,...
                                uint32(0));
                            if status == daq.ni.NIDAQmx.DAQmxSuccess
                                % Create a PXI module device information record for
                                % these devices
                                obj.addDevice(daq.ni.PXIDSAModule(obj,deviceName));
                            else
                                % Create a generic NI device information record for
                                % these devices                                
                                obj.addDevice(daq.ni.PCIDSADevice(obj,deviceName));
                            end
                        catch e
                            if strcmp(e.identifier, 'nidaq:ni:err201039')
                                % G660439: Ignore USB Firmware Loader
                                % Devices
                                return
                            end
                            obj.processUnknownDeviceException(...
                                e,...
                                deviceName,...
                                productCategory);
                         end
                   case {daq.ni.NIDAQmx.DAQmx_Val_Switches,...
                    	daq.ni.NIDAQmx.DAQmx_Val_SCXIModule,...
                        daq.ni.NIDAQmx.DAQmx_Val_SCCConnectorBlock,...
                    	daq.ni.NIDAQmx.DAQmx_Val_SCCModule,...
                    	daq.ni.NIDAQmx.DAQmx_Val_Unknown}

                        % Not defined in 8.7
                        % daq.ni.NIDAQmx.DAQmx_Val_NetworkDAQ,...
                        % daq.ni.NIDAQmx.DAQmx_Val_NIELVIS,...
                        %daq.ni.NIDAQmx.DAQmx_Val_SCExpress,...
                        
                        if daq.internal.getOptions().CompactDAQOnly
                            % We only return CompactDAQ devices
                            return
                        end
                        
                        % We don't know how to handle these.
                        obj.addDevice(daq.ni.UnknownDeviceInfo(obj,deviceName));
                    otherwise
                        % We don't know how to handle these.
                        obj.addDevice(daq.ni.UnknownDeviceInfo(obj,deviceName));
                end
            end
        end
        function summaryText = getOperationalSummaryImpl(obj)
            %getOperationalSummaryImpl returns diagnostic information
            summaryText = obj.OperationalSummary;
        end
    end
    
    % Private static methods
    methods (Static, Access = private)
        function operationalSummary = diagnoseMexLoadingProblem(mException, minimumAcceptableDriverVersion)
            
            expectedFilePath = fullfile(toolboxdir('daq'), 'daq', ...
                '+daq', '+ni', 'private', ['mexNIDAQmx.' mexext]);
            
            switch mException.identifier
                case 'MATLAB:UndefinedFunction'
                    % First make sure the MEX file exists.
                    if exist(expectedFilePath, 'file') == 0
                        operationalSummary = getString(message('nidaq:ni:MEXFileNotFound',...
                            expectedFilePath));
                    else
                        % Ensure that the MEX file is valid which is captured in
                        % the mException.message.
                        if ~isempty(strfind(mException.message, 'is not a valid'))
                            operationalSummary = getString(message('nidaq:ni:MEXFileCorrupt',...
                                mException.message));
                        else
                            % We don't have enough information to give a specific error.
                            operationalSummary = getString(message('nidaq:ni:couldNotLoadMEXFile',...
                                mException.identifier, mException.message));
                        end
                    end
                case 'MATLAB:invalidMEXFile'
                    % invalidMEXFile could mean that the file exists but
                    % isn't valid or that NI driver is not installed
                    % or is not the right revision. The exception message
                    % holds the key.
                    if ~isempty(strfind(mException.message, 'is not a valid'))
                        % The file is really corrupt.
                        operationalSummary = getString(message('nidaq:ni:MEXFileCorrupt',...
                            mException.message));
                    elseif  ~isempty(strfind(mException.message, 'The specified module could not be found'))
                        % This could mean that the MEX file does not exist.
                        % But if it existed and was removed it will be in
                        % the toolboxcache, so we can't use the EXIST or
                        % WHICH. DIR will tell us if the file really is
                        % there and works on both Windows and UNIX.
                        listing = dir(expectedFilePath);
                        if isempty(listing)
                            operationalSummary = getString(message('nidaq:ni:MEXFileNotFound',...
                                expectedFilePath));
                        else
                            % If our MEX file is there then the NI-DAQmx
                            % drivers are not installed or are not at the
                            % right revision.
                            operationalSummary = getString(message('nidaq:ni:MEXLoadErrorDriverIssue',...
                                num2str(minimumAcceptableDriverVersion), mException.message));
                        end
                    elseif ~isempty(strfind(mException.message, 'The specified procedure could not be found'))
                        % This means that the NI-DAQmx driver is not the
                        % right version.
                        operationalSummary = getString(message('nidaq:ni:MEXLoadErrorDriverIssue',...
                            num2str(minimumAcceptableDriverVersion), mException.message));
                    else
                        % We don't have enough information to give a specific error.
                        operationalSummary = getString(message('nidaq:ni:couldNotLoadMEXFile',...
                            mException.identifier, mException.message));
                    end
                otherwise
                    % We don't have a specific handler for this type of
                    % failure.  Give general diagnostic.
                    operationalSummary = getString(message('nidaq:ni:couldNotLoadMEXFile',...
                        mException.identifier, mException.message));
            end
        end
        
        function [driverPath] = getNIDAQmxDriverPath()
            % !!! Implement this (find the NI DLL)
            driverPath = 'n/a';
        end
    end
    
    methods ( Hidden, Access = private )
        function processUnknownDeviceException(obj,e,deviceName,productCategory)
            % Normally, we treat any failed load, as an
            % unknown device but if the 'FullDebug' option
            % is set, we log the results.
            if daq.internal.getOptions().FullDebug
                % Don't error (or later adaptors won't load), but
                % print the error report
                fprintf('===========Device %s, Product Category %d could not load==============\n',...
                    deviceName,productCategory)
                fprintf('%s\n',e.getReport())
                fprintf('========================================================\n')
            end
            % Create an unknown device record
            obj.addDevice(daq.ni.UnknownDeviceInfo(obj,deviceName));
        end
    end
end
