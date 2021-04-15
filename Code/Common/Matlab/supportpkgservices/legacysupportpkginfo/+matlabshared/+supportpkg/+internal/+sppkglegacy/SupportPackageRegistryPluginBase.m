classdef SupportPackageRegistryPluginBase < handle & matlab.mixin.Heterogeneous
    %SupportPackageRegistryPluginBase - base class for locating
    %support_package_registry.xml file for a support package
    %
    %   Support packages that ship a support_package_registry.xml file need to
    %   do the following in order for the support_package_registry.xml file to
    %   be found (and therbey execute any postInstallCmd, preUninstallCmd
    %   hooks during installation/uninstallation):
    %
    %   * In the top folder containing the "registry" folder of your support
    %   package, create the following package directory structure. This
    %   directory will need to be on the MATLAB path. If this directory cannot
    %   be placed on the MATLAB path, create a folder called "supportpkginfo"
    %   and create the package directory in that new folder. Add the new folder
    %   to the MATLAB path.
    %
    %   Package directory structure:
    %       +matlabshared/+supportpkg/+internal/+sppkglegacy/<subclassfile>
    %
    %   If the package directory is in the "supportpkginfo" or other custom
    %   location, then override the getRegistryFile() method to return the full
    %   path to the "registry" folder that contains the
    %   support_package_registry.xml file.
    %
    %   * In the +sppkglegacy directory, create a subclass of this class &
    %   define the BaseCode property
    %
    %   * Ensure that the directory containing the top level package directory
    %   (+matlabshared) is on the MATLAB path
    %
    %   * Ensure that the newly-created subclass is included in the MTF of your
    %   support package component
    %
    %   For information about how to create the derived class please see the
    %   wiki: http://inside.mathworks.com/wiki/Support_Package_Registry_Plugin
    %
    %   Copyright 2016 The MathWorks, Inc.
    
    properties(Abstract,Constant)
        %BaseCode - Support package base code, it should match the basecode
        %value in product xml. Each derived class should define the this
        %property based on support package product xml.
        BaseCode
    end
    
    properties(GetAccess = private, SetAccess = immutable)
        % Map of component names to function handles
        ComponentRemoveCmdMap;
    end
    
    properties(Constant)
        %XmlFileName - The name of support package registry file.
        XmlFileName = 'support_package_registry.xml'
        SpPkgXmlFolderName = 'registry';
    end
    
    
    methods (Access = public, Hidden)
        function registryDir = getRegistryFileDir(obj)
            % getRegistryFileDir - returns the location of the
            % support_package_registry.xml file
            %
            % --Example--
            % Location of support_package_registry.xml file:
            % $SPROOT/toolbox/target/supportpackages/android/registry/support_package_registry.xml
            % Location of MCOS plugin
            % SPROOT/toolbox/target/supportpackages/android/+matlabshared/+supportpkg/+internal/+sppkglegacy/DerivedClass.m
            %
            % This method will return:
            % $SPROOT/toolbox/target/supportpackages/android/registry
            %
            % by assuming the package directory (+matlabshared) is in the
            % same location as the "registry" folder. If this is not the
            % case, then derived classes need to override this method
            % and return the full path to the directory that contains the
            % support_package_registry.xml file
            derivedClassPath = obj.getClassPath();
            % The five fileparts remove the package directories and the
            % class name
            componentBaseDir = fileparts(fileparts(fileparts(fileparts(fileparts(derivedClassPath)))));
            % Add the "registry" folder
            registryDir = fullfile(componentBaseDir, obj.SpPkgXmlFolderName);
        end
        
        function fcnHandle = getRemoveCmdForComponent(obj, compName)
            % Method to return the function handle (removecmd) associated
            % with the given component name. If the component name does not
            % exist in the map, return an empty function handle.
            validateattributes(compName, {'char'}, {'nonempty'});
            fcnHandle = function_handle.empty;
            if isKey(obj.ComponentRemoveCmdMap, compName)
               fcnHandle = obj.ComponentRemoveCmdMap(compName);
            end
        end
    end
    
    methods(Access = protected)
        function addTpRemoveCmd(obj, componentName, fcnHandle)
           % This is the interface method called by individual plugins to
           % specify 3p component names to remove cmd function handles
           %
           % The specified remove cmd for a given component name will be
           % executed if  the current plugin is the only plugin found on
           % the MATLAB path that specifies the given component name
           
           validateattributes(componentName, {'char'}, {'nonempty'});
           validateattributes(fcnHandle, {'function_handle'}, {'nonempty', 'scalar'});
           if isKey(obj.ComponentRemoveCmdMap, componentName)
              error('Internal Error: Component name %s already added to map for plugin class %s', componentName, class(obj));
           end
           obj.ComponentRemoveCmdMap(componentName) = fcnHandle;
        end
    end
    
    methods (Sealed) % Methods called from heterogeneous array
        
        function compNames = getTpCompNames(obj)
            % Method to return all the component names from the
            % heterogeneous array of plugins
            compNames = [];
            for i =  1:length(obj)
               compNames= [compNames keys(obj(i).ComponentRemoveCmdMap)]; %#ok<AGROW>
            end
        end
        
        function compMap = getTpCompNameToBaseCodeMap(obj)
          % This method will loop over each object in the heterogeneous
          % array. For each object add the component names as keys whos
          % values are the basecode of the object
           compMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
           for i = 1:length(obj)
              compNames = keys(obj(i).ComponentRemoveCmdMap);
              if ~isempty(compNames)
                 compMap = matlabshared.supportpkg.internal.sppkglegacy.SupportPackageRegistryPluginBase.addBaseCodeToCompMap(obj(i).BaseCode, compMap, compNames);
              end
           end
        end
    end
    
    methods
        % Class constructor
        function obj = SupportPackageRegistryPluginBase()
            % Initialize the component name to remove cmd map
            obj.ComponentRemoveCmdMap = containers.Map();
        end
    end
    
    methods (Access = private)
        function derivedClassPath = getClassPath(obj)
            %getClassPath - returns full path to the class file
            %corresponding to this object. If this method is called from
            %the derived class, the full path to the derived class file is
            %returned.
            className = class(obj);
            derivedClassPath = which(className);
        end
    end
    
    methods(Static)
        function out =  findAllSpPkgLegacyInfoOnPath()
            %OUT = FINDSPPKGLEGACYINFOONPATH is a method to find classes of type
            %   matlabshared.supportpkg.internal.LegacySupportPackageRegistryInfo
            %   on the MATLAB path and instantiates them. OUT is an array
            %   of the instantiated objects.
            
            out = [];
            % Get all the plugin meta classes on the MATLAB path
            allPluginClasses = matlabshared.supportpkg.internal.findAllRegistryPlugins();
            % Get all the basecodes for the plugin meta classes
            allBaseCodes = matlabshared.supportpkg.internal.sppkglegacy.SupportPackageRegistryPluginBase.getBaseCodesFromPluginClasses(allPluginClasses);
            % Read the support package registry XMLs for all the plugins
            % found on the MATLAB path
             if isempty(allBaseCodes)
                return
             end
             out = matlabshared.supportpkg.internal.getSpPkgInfoForBaseCode(allBaseCodes);

        end
        
        function spPkg = readSpPkgRegistry(sppkgxml)
            %readSpPkgRegistry - read the support_package_registry.xml file
            % SPPKGXML and return an object who's property values are the
            % attributes found in the xml file. SPPKGXML is the full path
            % to the registry.xml file.
            validateattributes(sppkgxml, {'char'},{'nonempty'}, 'readSpPkgRegistry','sppkgxml');
            if ~exist(sppkgxml, 'file')
                error(message('supportpkgservices:registryplugin:MissingRegistryFile',sppkgxml));
            end
            spPkg = matlabshared.supportpkg.internal.LegacySupportPackageRegistryInfo();
            try
                domNode = xmlread(sppkgxml);
                pkgrepository = domNode.getDocumentElement();
                currpkg = pkgrepository.getElementsByTagName('SupportPackage');
                
                baseCode       = char(currpkg.item(0).getAttribute('basecode'));
                spPkg.BaseCode = baseCode;
                
                name = char(currpkg.item(0).getAttribute('name'));
                spPkg.Name = name;
                
                version = char(currpkg.item(0).getAttribute('version'));
                spPkg.Version = version;
                
                baseProduct = char(currpkg.item(0).getAttribute('baseproduct'));
                spPkg.BaseProduct = baseProduct;
                
                try
                    % This is an optional field - so it may not be
                    % available
                    extraInfoCheckBoxCmd = char(currpkg.item(0).getAttribute('extrainfocheckboxcmd'));
                    spPkg.ExtraInfoCheckBoxCmd = extraInfoCheckBoxCmd;
                catch
                end
                
                try
                    % This is an optional field since SPI would default
                    % this to "hardware"
                    supportCategory = char(currpkg.item(0).getAttribute('supportcategory'));
                    spPkg.SupportCategory = supportCategory;
                catch
                end
                % Default supportCategory is hardware
                if isempty(supportCategory)
                    spPkg.SupportCategory = 'hardware';
                end
                % This visible field should no longer be required if SSI is
                % enabled, but keeping for backwards compatibility with
                % AddOns Manager
                visible = char(currpkg.item(0).getAttribute('visible'));
                spPkg.Visible = logical(str2double(visible));
                
                fwUpdate       = char(currpkg.item(0).getAttribute('firmwareupdate'));
                spPkg.FwUpdate = fwUpdate;
                
                postInstallCmd = char(currpkg.item(0).getAttribute('postinstallcmd'));
                spPkg.PostInstallCmd = postInstallCmd;
                
                preUninstallCmd = char(currpkg.item(0).getAttribute('preuninstallcmd'));
                spPkg.PreUninstallCmd = preUninstallCmd;
                
                customMWLicenseFiles = char(currpkg.item(0).getAttribute('custommwlicensefiles'));
                spPkg.CustomMWLicenseFiles = customMWLicenseFiles;
                
                spPkg.RegistryXmlLoc = sppkgxml;
                
                
                displayName       = char(currpkg.item(0).getAttribute('displayname'));
                spPkg.FwUpdateDisplayName = char(currpkg.item(0).getAttribute('fwupdatedisplayname'));
                
                if ~isempty(spPkg.FwUpdate)
                    matlabshared.supportpkg.internal.sppkglegacy.SupportPackageRegistryPluginBase.populateFwUpdateDisplayName(...
                        spPkg, displayName, name, baseProduct);
                end
                
            catch ex
                baseException = MException(message('supportpkgservices:registryplugin:UnexpectedSupportPackageFormat', sppkgxml ));
                baseException = addCause(baseException,ex);
                throwAsCaller(baseException);
            end
        end
        
        function [spPkgBaseCodeCell,spPkgClassLocCell]  = getBaseCodesFromPluginClasses(pluginMetaClasses)
            % Static utility method that will return all the basecodes
            % specified in the plugin meta classes provided. It will also
            % return the corresponding paths to the plugin classes
            validateattributes(pluginMetaClasses, {'meta.class'},{});
            spPkgBaseCodeCell = {};
            spPkgClassLocCell = {};
            if isempty(pluginMetaClasses)
                % If no support package derived class found on the path,
                % return empty.
                return
            end
            % Create cell array of basecodes
            spPkgBaseCodeCell = cell(size(pluginMetaClasses));
            % The class location cell array is used for debugging.
            spPkgClassLocCell = cell(size(pluginMetaClasses));
            % Capture all the basecodes found in the plugin classes into
            % the basecode cell array
            for i = 1:numel(pluginMetaClasses)
                spPkgBaseCodeCell{i} = pluginMetaClasses(i).PropertyList(...
                    strcmp({pluginMetaClasses(i).PropertyList.Name},'BaseCode')).DefaultValue;
                spPkgClassLocCell{i} = which(pluginMetaClasses(i).Name);
            end
        end
        
        function pluginClass = findSpPkgPluginForBaseCode(basecode, pluginMetaClasses)
            %findSpPkgPluginForBaseCode - return the plugin class that
            %   corresponds to the specified basecode in the list of
            %   plugin meta classes
            %
            %   If no plugin for the specified basecode is found, then
            %   return meta.class.empty
            
            validateattributes(basecode, {'char'}, {'nonempty'}, 'findSpPkgPluginForBaseCode', 'basecode');
            validateattributes(pluginMetaClasses, {'meta.class'}, {}, 'findSpPkgPluginForBaseCode', 'allPluginClasses');
            pluginClass = meta.class.empty;
            [spPkgBaseCodeCell, ~] = matlabshared.supportpkg.internal.sppkglegacy.SupportPackageRegistryPluginBase.getBaseCodesFromPluginClasses(pluginMetaClasses);
            % Find the requested basecode
            idx = strcmp(spPkgBaseCodeCell,basecode);
            if ~any(idx)
                % If no plugin was found for the specified basecode, return
                % empty object
                return;
            end
            if numel(find(idx)) > 1
                % If multiple plugins are found with the specified basecode
                % throw an error
                error(message('supportpkgservices:registryplugin:MultipleSpsWithSameBaseCode',strjoin({pluginMetaClasses(idx).Name},'\n')));
            end
            pluginClass = pluginMetaClasses(idx);
        end
        
        function allPluginObjects = constructPluginClasses(metaClasses)
            % Static helper function to construct objects from the array of
            % meta classes
            
            validateattributes(metaClasses, {'meta.class'}, {'nonempty'})
            
            % Create heterogenous array of plugin objects
            allPluginObjects = [];
            for i = 1:numel(metaClasses)
                allPluginObjects = [allPluginObjects feval(metaClasses(i).Name)]; %#ok<AGROW>
            end
        end
        
        function populateFwUpdateDisplayName(legacySpPkgInfo, dpName, name, baseProduct)
            % POPULATEFWUPDATEDISPLAYNAME constructs and assigns the
            % FwUpdateDisplayName property of the LegacySupportPackageInfo
            % object.
            
            str2match = 'hwsetup:';
            isHWSetup = strncmp(legacySpPkgInfo.FwUpdate, str2match , numel(str2match));            
            % Legacy targetupdater workflow
            if ~isHWSetup
                matlabshared.supportpkg.internal.sppkglegacy.SupportPackageRegistryPluginBase.getLegacyFwUpdateDisplayName(...
                    legacySpPkgInfo, dpName, name, baseProduct);
            % HW Setup Workflow
            else
                matlabshared.supportpkg.internal.sppkglegacy.SupportPackageRegistryPluginBase.getHwSetupFwUpdateDisplayName(...
                    legacySpPkgInfo);                
            end
        end
        
        function getLegacyFwUpdateDisplayName(legacySpPkgInfo, dpName, name, baseProduct)
            % GETLEGACYFWUPDATEDISPLAYNAME constructs and assigns the display name for 
            % the legacy targetupdater workflow based on the display name 
            % of the Support Package and the Base Product if the 
            % FwUpdateDisplayName has not been explicitly specified
            
            if isempty(legacySpPkgInfo.FwUpdateDisplayName)
                % Get the DisplayName and BaseProduct to populate the
                % FwUpdateDisplayName field
                if isempty(dpName)
                    legacySpPkgInfo.FwUpdateDisplayName = [name ' (' baseProduct ')'];
                else
                    legacySpPkgInfo.FwUpdateDisplayName = [dpName ' (' baseProduct ')'];
                end
            end
        end
        
        function getHwSetupFwUpdateDisplayName(legacySpPkgInfo)
            % GETHWSETUPFWUPDATEDISPLAYNAME constructs and assigns the
            % display name for the HW Setup workflow
            
            % Find the characters follwoing the string "hwsetup:" as
            % specified in the FwUpdate property. These specify the name of
            % the Workflow Class
            splitStr = strsplit(legacySpPkgInfo.FwUpdate, 'hwsetup:');
            assert(isequal(numel(splitStr),2), 'FwUpdate field for HW Setup workflow should be of the format "hwsetup:workflowClassName"')
            workflowName = splitStr{2};
            assert(~isempty(workflowName), 'FwUpdate field for HW Setup workflow should be of the format "hwsetup:workflowClassName"');
            classInfo = meta.class.fromName(workflowName);
            if ~isempty(classInfo)
                allProperties = {classInfo.PropertyList.Name};
                % The Name property of the Workflow class specifies the HW
                % Setup Worflow Name as displayed on the UI
                idx = strcmp(allProperties, 'Name');
                legacySpPkgInfo.FwUpdateDisplayName = classInfo.PropertyList(idx).DefaultValue;
            end
        end
    end
    
    methods( Access = private, Static)
    
         function compMap = addBaseCodeToCompMap(baseCode, compMap, compNames)
            % Static helper function that will add the provided baseCode to
            % the component map using the provided component names as keys.
            % If any component name already exists as a key, grow the cell
            % array of basecodes for that component name key
            
            for i = 1:length(compNames)
               if isKey(compMap, compNames{i})
                   compMap(compNames{i}) = [compMap(compNames{i}) {baseCode}];
               else
                   compMap(compNames{i}) = {baseCode};
               end
            end
        end
    end
end
