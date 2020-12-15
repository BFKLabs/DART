classdef (CaseInsensitiveProperties, TruncatedProperties) videosource < imaq.internal.PropertyContainer
    %VIDEOSOURCE Construct a video source object.
    %
    %    Video source objects are automatically created when
    %    a video input object is created using VIDEOINPUT.
    %
    %    This function is not intended to be used directly by the user. This
    %    class defines CaseInsensitiveProperties and TruncatedProperties to
    %    maintain backward comptability with the previous udd videosource
    %    class.
    %
    %    See also IMAQHELP, VIDEOINPUT.
    %
    %   Copyright 2012-2013 The MathWorks, Inc.
    
    properties(SetAccess = immutable, GetAccess = public, SetObservable)
        
        % Parent is the parent videoinput udd object
        Parent = '';
        
        % A char indicating the name of the videosource object
        SourceName = '';
        
        % This is same as class of this object. Kept for backward
        % comptability reasons.
        Type = 'videosource';
    end
    
    properties(Access = public, SetObservable)
        
        % A char identifying the videosource object
        Tag = '';
        
        % A char representing if the videosource device is selected.
        % Possible values are on/off.
        Selected
    end
    
    properties (SetAccess = private, GetAccess = public, Hidden)
        InspectorHandle;
    end
    
    properties ( Access = private, Hidden )
        % A map between property name and its index in the internal
        % property container
        propertyIndexMap;
    end
    
    methods(Access=public, Hidden)
        
        function result = isArrayProperty(obj,propName)
            result = false;
            pc = obj.InternalPropertyContainer;
            index = getIndexPropertyContainerIndex(obj,propName);
            switch pc.Properties(index).Type
                case 'integer'
                    if pc.Properties(index).StorageType ~= 4
                        result = true;
                    end
                case 'double'
                    if  pc.Properties(index).StorageType ~= 2
                        result = true;
                    end
            end
        end
        
        function privateDelete(obj)
            % This method is used by internal IMAQ functions like imaqreset to
            % delete the videosource object. The destructor of videosource is
            % private so that a user cannot call delete explicitly on the
            % videosource object.
            % Close the inspector windows.
            if all(isvalid(obj))
                allHandles = {obj.InspectorHandle};
                for idx = 1:length(allHandles)
                    if ~isempty(allHandles{idx})
                        allHandles{idx}.dispose();
                    end
                end
            end
            delete(obj);
        end
        
        function obj = videosource(name, parent, propContainer)
            % TODO: resolve whether to use mlock here to prevent warning on
            % exit, and then when to munlock it.
            % mlock;
            obj.SourceName = name;
            obj.Parent = parent;
            obj.propertyIndexMap = containers.Map;
            %The internal property conatiner represents the MCOS C++
            %conatiner imaqpropsys
            obj.InternalPropertyContainer = propContainer;
            
            % Add all device specific properties
            obj.addDeviceSpecificProps();
        end
        
        function prop = getProperty(obj, propertyName)
            mySourceName = obj.SourceName;
            pc = obj.InternalPropertyContainer;
            currentSourceName = pc.SelectedSourceName;
            if ~strcmp(mySourceName, currentSourceName)
                pc.SelectedSourceName = mySourceName;
            end
            oc = onCleanup(@()obj.cleanup(pc, currentSourceName));
            for pp=1:length(pc.Properties)
                if strcmp(propertyName, pc.Properties(pp).Name) && ~strcmp(pc.Properties(pp).Type, 'Command')
                    % Commands are properties internally, but not to
                    % callers of this method.
                    prop = pc.Properties(pp);
                    pc.SelectedSourceName = currentSourceName;
                    return;
                end
            end
            switch propertyName
                case 'Parent'
                    prop.DeviceSpecific = false;
                    prop.ReadOnly = 'always';
                    prop.Visibility = 'common';
                    prop.Type = 'videoinput';
                    prop.Accessible = true;
                    prop.Categories = '';
                    prop.StringValue = [];
                    prop.StringDefault = [];
                case 'SourceName'
                    prop.DeviceSpecific = false;
                    prop.ReadOnly = 'always';
                    prop.Visibility = 'common';
                    prop.Type = 'string';
                    prop.Accessible = true;
                    prop.Categories = '';
                    prop.StringValue = [];
                    prop.StringDefault = '';
                case 'Type'
                    prop.DeviceSpecific = false;
                    prop.ReadOnly = 'always';
                    prop.Visibility = 'common';
                    prop.Type = 'string';
                    prop.Accessible = true;
                    prop.Categories = '';
                    prop.StringValue = 'videosource';
                    prop.StringDefault = 'videosource';
                case 'Selected'
                    prop.DeviceSpecific = false;
                    prop.ReadOnly = 'always';
                    prop.Visibility = 'common';
                    prop.Type = 'enum';
                    prop.Accessible = true;
                    prop.Categories = '';
                    prop.StringValue = [];
                    prop.StringDefault = '';
                    prop.EnumDefault = 'off';
                    prop.EnumAllowedStrings = {'off', 'on'};
                case 'Tag'
                    prop.DeviceSpecific = false;
                    prop.ReadOnly = 'never';
                    prop.Visibility = 'common';
                    prop.Type = 'string';
                    prop.Accessible = true;
                    prop.Categories = '';
                    prop.StringValue = '';
                    prop.StringDefault = '';
                otherwise
                    error('imaq:videosource:propertyNotFound', 'Invalid property name.');
            end
        end
        
        
        function addDeviceSpecificProps(obj)
            % Adds device specific properties from adaptor to the videosource
            % objects
            
            % Get the internal container
            internalPropertyContainer = obj.InternalPropertyContainer;
            
            % Loop through all the properties in the internal container and
            % add them dynamically to the videosource object
            for pp=1:length(internalPropertyContainer.Properties)
                
                % Set the property name
                property.Name = internalPropertyContainer.Properties(pp).Name;
                
                % Set the read only property
                property.ReadOnly = false;
                
                % Add the property dynamically
                prop = obj.addDynamicProp(property);
                
                % Make the 'command' property hidden
                if strcmp(internalPropertyContainer.Properties(pp).Type, 'command')
                    prop.Hidden = true;
                end
                
                % Store the index relative to the name of the property.
                obj.propertyIndexMap(property.Name) = pp;
                
            end
        end
        
        function setValueOnProperty(obj, propertyName, value)
            mySourceName = obj.SourceName;
            pc = obj.InternalPropertyContainer;
            currentSourceName = pc.SelectedSourceName;
            if ~strcmp(mySourceName, currentSourceName) && ~obj.PerformingGet
                pc.SelectedSourceName = mySourceName;
            end
            
            oc = onCleanup(@()obj.cleanup(pc, currentSourceName));
            
            try
                for pp=1:length(pc.Properties)
                    if strcmp(propertyName, pc.Properties(pp).Name)
                        pc.Properties(pp).FireListeners = strcmp(mySourceName, currentSourceName);
                        pInfo = propinfo(obj,pc.Properties(pp).Name);
                        switch pc.Properties(pp).Type
                            case 'integer'
                                if ~isnumeric(value)
                                    error('testmeas:property:numeric','Property value should be numeric. See PROPINFO(OBJ,''PROPERTY'').')
                                end
                                if ~isfinite(value)
                                    error('testmeas:property:finite','Property value should be finite. See PROPINFO(OBJ,''PROPERTY'').')
                                end
                                
                                % Check for int32 max and min bounds
                                if value > intmax
                                    error('testmeas:property:aboveMaximum','Property value can not be set above the maximum value constraint. See PROPINFO(OBJ,''PROPERTY'').)')
                                end
                                if value < intmin
                                    error('testmeas:property:belowMinimum','Property value can not be set below the minimum value constraint. See PROPINFO(OBJ,''PROPERTY'').)')
                                end
                                
                                value = int32(value);
                                if strcmp(pInfo.Constraint,'bounded')
                                    if any(value < pc.Properties(pp).IntLowerBound)
                                        error('testmeas:property:belowMinimum','Property value can not be set below the minimum value constraint. See PROPINFO(OBJ,''PROPERTY'').)')
                                    end
                                    
                                    if any(value > pc.Properties(pp).IntUpperBound )
                                        error('testmeas:property:aboveMaximum','Property value can not be set above the maximum value constraint. See PROPINFO(OBJ,''PROPERTY'').)')
                                    end
                                end
                                if pc.Properties(pp).StorageType == 4 %Not an array
                                    if ~isscalar(value)
                                        error('MATLAB:class:MustBeScalar','Parameter must be scalar.');
                                    end
                                    pc.Properties(pp).IntValue = value;
                                elseif pc.Properties(pp).IsPairProperty % It is an array
                                    if ~all(size(value) == [ 1,2])
                                        error('testmeas:set:pairDbl','Property must be a 1x2 vector of numeric values.');
                                    end
                                    pc.Properties(pp).IntArrayValue = value;
                                else
                                    if ~isempty(value) || ~isempty(pc.Properties(pp).IntArrayValue)
                                        pc.Properties(pp).IntArrayValue = value;
                                    end
                                end
                            case 'string'
                                if ~ischar(value)
                                    error('testmeas:property:char','Property value should be a string. See PROPINFO(OBJ,''PROPERTY'').')
                                end
                                pc.Properties(pp).StringValue = value;
                            case 'enum'
                                if ~ischar(value)
                                    error('testmeas:property:char','Property value should be a string. See PROPINFO(OBJ,''PROPERTY'').')
                                end
                                
                                if ~ismember(lower(value),lower(pc.Properties(pp).EnumAllowedStrings))
                                    error('testmeas:set:enum','There is no enumerated value named ''%s'' for the ''%s'' property. See PROPINFO(OBJ,''PROPERTY'').',value,...
                                        pc.Properties(pp).Name);
                                end
                                for i = 1:numel(pc.Properties(pp).EnumAllowedStrings)
                                    if strcmpi(value,pc.Properties(pp).EnumAllowedStrings{i})
                                        value = pc.Properties(pp).EnumAllowedStrings{i};
                                        break;
                                    end
                                end
                                pc.Properties(pp).EnumValue = value;
                            case 'double'
                                if ~isnumeric(value)
                                    error('testmeas:property:numeric','Property value should be numeric. See PROPINFO(OBJ,''PROPERTY'').')
                                end
                                if strcmp(pInfo.Constraint,'bounded')
                                    if any(value < pc.Properties(pp).DoubleLowerBound)
                                        error('testmeas:property:belowMinimum','Property value can not be set below the minimum value constraint. See PROPINFO(OBJ,''PROPERTY'').)')
                                    end
                                    
                                    if any(value > pc.Properties(pp).DoubleUpperBound )
                                        error('testmeas:property:aboveMaximum','Property value can not be set above the maximum value constraint. See PROPINFO(OBJ,''PROPERTY'').)')
                                    end
                                end
                                if pc.Properties(pp).StorageType == 2
                                    if ~isscalar(value)
                                        error('MATLAB:class:MustBeScalar','Parameter must be scalar.');
                                    end
                                    pc.Properties(pp).DoubleValue = value;
                                elseif pc.Properties(pp).IsPairProperty % It is an array
                                    if ~all(size(value) == [ 1,2])
                                        error('testmeas:set:pairDbl','Property must be a 1x2 vector of numeric values.');
                                    end
                                    pc.Properties(pp).DoubleArrayValue = value;
                                else
                                    pc.Properties(pp).DoubleArrayValue = value;
                                end
                            otherwise
                        end
                        break;
                    end
                end
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function h = createDynamicPropertyGetter(obj,propertyName)
            h = @updatePropertyValue;
            
            function value = updatePropertyValue(src,evt) %#ok<INUSD>
                mySourceName = obj.SourceName;
                pc = obj.InternalPropertyContainer;
                currentSourceName = pc.SelectedSourceName;
                if ~strcmp(mySourceName, currentSourceName)
                    pc.SelectedSourceName = mySourceName;
                end
                
                oc = onCleanup(@()obj.cleanup(pc, currentSourceName));
                
                index = obj.getIndexPropertyContainerIndex(propertyName);
                prop = pc.Properties(index);
                prop.FireListeners = strcmp(mySourceName, currentSourceName);
                obj.PerformingGet = true;
                switch prop.Type
                    case 'integer'
                        if prop.StorageType == 4
                            value = prop.IntValue;
                        else
                            value = prop.IntArrayValue;
                        end
                    case 'string'
                        value = prop.StringValue;
                    case 'enum'
                        value = prop.EnumValue;
                    case 'double'
                        if prop.StorageType == 2
                            value = prop.DoubleValue;
                        else
                            value = prop.DoubleArrayValue;
                        end
                    otherwise
                end
            end
        end
        
        function cleanup(obj,pc,sourceName)
            obj.PerformingGet = false;
            pc.SelectedSourceName = sourceName;
        end
    end
    
    methods
        function disp(obj)
            
            if isempty(obj)
                builtin('disp',obj);
                return;
            end
            indent = blanks(3);
            
            % Determine if we want a compact or loose display.
            isloose = strcmp(get(0,'FormatSpacing'),'loose');
            if isloose,
                newline = sprintf('\n');
            else
                newline = sprintf('');
            end
            fprintf(newline);
            
            childHeading = [indent 'Display Summary for Video Source Object'];
            table = internal.DispTable();
            table.Indent =7;
            table.addColumn('Index')
            table.addColumn('SourceName')
            table.addColumn('Selected')
            
            if ~all(isvalid(obj))
                for i = 1:length(obj)
                    table.addRow(i,'Invalid', 'Invalid');
                end
            end
            
            if (length(obj)==1) && isvalid(obj)
                fprintf('%s:\n%s', childHeading, newline);
            elseif (length(obj)==1) && ~isvalid(obj)
                fprintf('%s:\n%s', childHeading, newline);
                table.disp();
                return;
            elseif ~all(isvalid(obj))
                fprintf('%s Array:\n%s', childHeading, newline);
                table.disp();
                return;
            else
                table = internal.DispTable();
                table.Indent =7;
                table.addColumn('Index')
                table.addColumn('SourceName')
                table.addColumn('Selected')
                fprintf('%s Array:\n%s', childHeading, newline);
                for i = 1:length(obj)
                    table.addRow(i,['''' obj(i).SourceName ''''], ['''' obj(i).Selected '''']);
                end
                table.disp;
                return;
            end
            
            obj.propertiesDisplay()
        end
    end
    
    methods( Access = private )
        
        function propertiesDisplay(obj)
            propertyNames = properties(obj);
            [ ~, iS]  = sort(lower(propertyNames));
            sortedpropertyNames = propertyNames(iS);
            
            generalProperties = '';
            deviceSpecificProperties = '';
            
            cr = sprintf('\n');
            
            for i=1:length(sortedpropertyNames)
                if strcmp(sortedpropertyNames{i},'Parent')
                    strToDisp = [sprintf('        %s = [1x1 videoinput]', sortedpropertyNames{i}), cr];
                else
                    propertyToDisplay = obj.([sortedpropertyNames{i}]);
                    if isnumeric(propertyToDisplay) && ~isscalar(propertyToDisplay) % display for arrays
                        arrayStr = sprintf('%.5g ',propertyToDisplay);
                        strToDisp = sprintf('        %s = [%s', sortedpropertyNames{i}, arrayStr);
                        strToDisp(end) =  ']';
                        strToDisp(end+1) = cr; %#ok<AGROW>
                    elseif isempty(propertyToDisplay) % empty property case
                        pInfo = propinfo(obj,sortedpropertyNames{i});
                        strToDisp = [sprintf('        %s = [%dx%d %s]', sortedpropertyNames{i}, size(propertyToDisplay),pInfo.Type), cr];
                    else
                        strToDisp = [sprintf('        %s = %s', sortedpropertyNames{i}, num2str(propertyToDisplay)), cr];                        
                    end
                end
                index = obj.getIndexPropertyContainerIndex(sortedpropertyNames{i});
                if isempty(index)
                    generalProperties = [ generalProperties strToDisp]; %#ok<AGROW>
                elseif obj.InternalPropertyContainer.Properties(index).DeviceSpecific
                    deviceSpecificProperties = [ deviceSpecificProperties strToDisp]; %#ok<AGROW>
                else
                    generalProperties = [ generalProperties strToDisp]; %#ok<AGROW>
                end
            end
            
            fprintf('      General Settings:%s%s%s', cr, generalProperties, cr);
            
            if ~isempty(deviceSpecificProperties)
                fprintf('      Device Specific Properties:%s%s%s', cr, deviceSpecificProperties, cr);
            end
            
            
        end
    end
    methods( Hidden)
        function helpTxt = prophelp(obj,propertyName)
            helpTxt = '';
            
            index = getIndexPropertyContainerIndex(obj,propertyName);
            
            %get the property container for the specific property
            propertyInfo = obj.InternalPropertyContainer.Properties(index);
            
            helpTxt = [helpTxt '     ' upper(propertyName) ' ' propertyInfo.Type '    '];
            
            if isempty(index)
                additionalHelp = getHelpTextFromIMDF(obj,propertyName);
                helpTxt = [ helpTxt  '      (Read-only: never)'];
                % get help from imdf files directly
            else
                switch propertyInfo.Type
                    case 'integer'
                        helpTxt = [ helpTxt ....
                            '   [' ....
                            num2str(propertyInfo.IntLowerBound) ' ' ...
                            num2str(propertyInfo.IntUpperBound) ']'];
                    case 'double'
                        helpTxt = [ helpTxt ....
                            '   [' ....
                            num2str(propertyInfo.DoubleLowerBound) ' ' ...
                            num2str(propertyInfo.DoubleUpperBound) ']'];
                    case 'enum'
                    case 'string'
                    otherwise
                end
                helpTxt = [ helpTxt  '      (Read-only: ' propertyInfo.ReadOnly ')'];
                additionalHelp = getHelp(propertyInfo);
            end
            helpTxt = [ helpTxt additionalHelp];
            
        end
        
    end
    
    methods (Access=public)
        
        function inspect(obj)
            % Perform error checking
            if length(obj)>1
                error(message('imaq:inspect:OBJ1x1'));
            elseif ~isvalid(obj.Parent)
                error(message('imaq:inspect:invalidOBJ'));
            end
            
            obj.InspectorHandle = imaq.propertyInspector.getInstance.show(obj);
        end
        
        function newobj = horzcat(varargin)
            %HORZCAT Horizontal concatenation for image acquisition videosource
            %objects.
            
            for i=1:nargin-1
                
                % If an empty object is passed in , ignore it
                if isempty(varargin{i})
                    continue;
                end
                
                %
                cmp = varargin{i};
                if numel(varargin{i}) ~= 1
                    cmp = cmp(1);
                end
                
                % Error out if video sources object with different parents
                % are concatenated.
                if cmp.Parent ~= varargin{i+1}.Parent
                    error(message('imaq:horzcat:differentParent'));
                end
            end
            newobj = builtin('horzcat',varargin{:});
        end
        
        function newobj = vertcat(varargin)
            for i=1:nargin-1
                if isempty(varargin{i}) || isempty(varargin{i})
                    continue;
                end
                if varargin{i}.Parent ~= varargin{i+1}.Parent
                    error(message('imaq:vertcat:differentParent'));
                end
            end
            newobj = builtin('vertcat',varargin{:});
        end
        
    end
    
    methods
        function val = get.Selected(obj)
            pc = obj.InternalPropertyContainer;
            if strcmp(pc.SelectedSourceName, obj.SourceName)
                val = 'on';
            else
                val = 'off';
            end
        end
        
        function varargout = get(obj, varargin)
            
            if ~all(isvalid(obj))
                error(message('MATLAB:class:InvalidHandle'))
            end
            
            
            if nargin == 1 && nargout == 0 % user called get(obj)
                if (length(obj) > 1)
                    error(message('imaq:get:vectorOBJ'));
                else
                    propertiesDisplay(obj);
                end
            end
            
            if nargout > 0 || nargin > 1
                varargout = {get@hgsetget(obj,varargin{:})};
            end
            
            
            if nargout > 0 && nargin == 1 % user calls out = get(obj)
                sortedGet  = struct([]);
                for index = 1:length(obj)
                    unSortedGet = get@hgsetget(obj(index));
                    f = sort(fieldnames(unSortedGet));
                    for i = 1:length(f)
                        sortedGet(index,1).(f{i}) = unSortedGet.(f{i});
                    end
                end
                varargout = {sortedGet};
            end
        end
        
        function varargout = set(obj, varargin)
            % Set only works for scalar objects
            if ~isscalar(obj)
                error(message('imaq:set:vectorOBJ'));
            end
            
            try
                %% set(obj)
                if nargin == 1  && nargout == 0
                    sortedGeneralProperties = obj.getGeneralPropertyNames();
                    sortedDeviceSpecificProperties = obj.getDeviceSpecificPropertyNames();
                    
                    fprintf('%3s%s\n','',  'General Settings:');
                    for propIndex = 1:numel(sortedGeneralProperties)
                        % Get propertInfo to determine type and read-only status of a
                        % property.
                        pInfo = propinfo(obj,sortedGeneralProperties{propIndex});
                        if strcmp(pInfo.ReadOnly,'always')
                            continue;
                        end
                        fprintf('%4s%s\n','', sortedGeneralProperties{propIndex})
                    end
                    fprintf('\n');
                    
                    % Show device properties if they exists.
                    if ~isempty(sortedDeviceSpecificProperties)
                        fprintf('%2s%s\n','','Device Specific Properties:');
                        for propIndex = 1:numel(sortedDeviceSpecificProperties)
                            % Get propertInfo to determine type and read-only status of a
                            % property.
                            if obj.isEnum(sortedDeviceSpecificProperties{propIndex})
                                fprintf('%4s%s:%s\n','',sortedDeviceSpecificProperties{propIndex},...
                                    obj.getDisplayTextForEnumProperty(sortedDeviceSpecificProperties{propIndex}))
                            else
                                fprintf('%4s%s\n','', sortedDeviceSpecificProperties{propIndex})
                            end
                        end
                        fprintf('\n');
                    end
                    return;
                end
                
                %% out = set(obj)
                if nargin == 1 && nargout == 1
                    a = struct;
                    sortedPropertyNames = obj.getAlphabeticallySortedPropertyNames();
                    
                    for i=1:length(sortedPropertyNames)
                        p = propinfo(obj,sortedPropertyNames{i});
                        if strcmp(p.ReadOnly,'always')
                            continue;
                        end
                        if obj.isEnum(sortedPropertyNames{i})
                            a.(sortedPropertyNames{i}) = p.ConstraintValue';
                        else
                            a.(sortedPropertyNames{i}) = {};
                        end
                    end
                    varargout = {a};
                    return;
                end
                
                %% set(obj,'PropName')
                if nargin == 2
                    propName = varargin{1};
                    if ~isstruct(propName)
                        pInfo = propinfo(obj,propName);
                        if obj.isEnum(propName)
                            strToDisp = sprintf('%s\n',obj.getDisplayTextForEnumProperty(propName));
                            out = pInfo.ConstraintValue';
                        else
                            strToDisp = sprintf('The ''%s'' property does not have a fixed set of property values.\n', propName);
                            out = {};
                        end
                        if nargout ~= 0
                            varargout = {out};
                        else
                            fprintf(strToDisp);
                        end
                        return;
                    end
                end
                
                %% set(obj,'PropName','PropValue')
                %% out = set(obj,'PropName','PropValue')
                out = {set@hgsetget(obj,varargin{:})};
                if nargout ~= 0
                    varargout = out;
                end
                
                
            catch ME
                ME.throwAsCaller;
            end
            
            
        end
        
        
        function output = imaqfind(obj,varargin)
            % Pass the work to the private function
            try
                output = imaqgate('privateFindObj', obj, varargin{:});
            catch exception
                throw(exception);
            end
        end
    end
    
    
    methods(Access = private)
        
        function result = getHelpTextFromIMDF(obj,propertyName) %#ok<INUSL>
            % Get help text from XML file for a particular property
            
            %Intialize the text
            result = '';
            
            % Read the imdf file
            tree = xmlread([matlabroot filesep 'toolbox' filesep 'imaq' filesep 'imaq' filesep 'private' filesep 'imaqmex.imdf']);
            % Find the AdaptorHelp tag
            childNodes = tree.getElementsByTagName('AdaptorHelp');
            
            % Find the particular property among all the nodes
            for i = 0:childNodes.getLength()
                if strcmp(childNodes.item(i).getAttribute('property').toString,...
                        propertyName)
                    %Get the help text
                    result = char(childNodes.item(i).getFirstChild.getData);
                    
                    % Also add the See Also text
                    seeAlso = childNodes.item(i).getElementsByTagName('SeeAlso').item(0).item(0).getData;
                    result = [result ...
                        ' See also ' char(seeAlso)]; %#ok<AGROW>
                    return;
                end
            end
        end
        
        function delete(obj) %#ok<INUSD>
            % Destructor is made private so that users can not explicitly
            % delete a videosource object.
        end
        
        function index = getIndexPropertyContainerIndex(obj,propertyName)
            % A helper function to get the index of a property in the
            % internal property container. Return empty if the property is
            % not found.
            if isKey(obj.propertyIndexMap,propertyName)
                index = obj.propertyIndexMap(propertyName);
            else
                index = [];
            end
            
        end
        
        % Sort based on the lower case, however return the correct case.
        function result = sortAlphabetically(obj,propertyNames) %#ok<INUSL>
            [ ~, iS]  = sort(lower(propertyNames));
            result = propertyNames(iS);
        end
        
        function result =  getAlphabeticallySortedPropertyNames(obj)
            result = obj.sortAlphabetically(properties(obj));
        end
        
        function result = getDisplayTextForEnumProperty(obj,propName)
            pInfo = propinfo(obj,propName);
            result = '[';
            for indexConstraintValue = 1:length(pInfo.ConstraintValue)
                if strcmp(pInfo.ConstraintValue{indexConstraintValue},pInfo.DefaultValue)
                    result = [ result sprintf(' {%s} ',pInfo.ConstraintValue{indexConstraintValue})]; %#ok<AGROW>
                else
                    result = [ result sprintf(' %s ',pInfo.ConstraintValue{indexConstraintValue})]; %#ok<AGROW>
                end
                if indexConstraintValue ~= length(pInfo.ConstraintValue)
                    result = [ result '|']; %#ok<AGROW>
                end
            end
            result(end+1) = ']';
        end
    end
    
    methods (Access = private)
        function result = getDeviceSpecificPropertyNames(obj)
            propertyNames = sortAlphabetically(obj,properties(obj));
            result = propertyNames(cellfun(@(x) ~isempty(obj.getIndexPropertyContainerIndex(x)), ...
                propertyNames));
            
        end
        
        function result = getGeneralPropertyNames(obj)
            propertyNames = sortAlphabetically(obj,properties(obj));
            result = propertyNames(cellfun(@(x) isempty(obj.getIndexPropertyContainerIndex(x)), ...
                propertyNames));
            
        end
        
        function result = isEnum(obj,propName)
            index = obj.getIndexPropertyContainerIndex(propName);
            if isempty(index)
                result = false;
                return;
            end
            result = strcmp(obj.InternalPropertyContainer.Properties(index).Type,'enum');            
        end
    end
    
    
    
end

