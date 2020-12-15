classdef (Hidden) SubsystemInfo < daq.internal.BaseClass & daq.internal.UserDeleteDisabled
    %SubsystemInfo Information about a subsystem on a device
    %    The specializations of this class are subclassed by
    %adaptors to provide additional information about a
    %particular subsystem implementation.  They may choose to
    %add custom properties and methods.
    
    % Copyright 2009-2012 The MathWorks, Inc.
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties (SetAccess = private)
        %MeasurementTypesAvailable A cell array of strings representing
        %the types of measurements that this subsystem support
        %(voltage, current, etc.).
        MeasurementTypesAvailable
        
        %DefaultMeasurementType A string representing the default
        %measurement type to use with this subsystem, if the user does not
        %specify.
        DefaultMeasurementType;
        
        %NativeDataType A string representing the data type used by
        %this subsystem to return data in native mode.
        NativeDataType
        
        %SubsystemType a string describing if it is an analog
        %input, output, etc.
        SubsystemType
        
        %NumberOfChannelsAvailable The number of channels supported by the
        %subsystem when configured for the maximum number of channels
        NumberOfChannelsAvailable
        
        %ChannelNames The name list of channels supported by the
        %subsystem when configured for the maximum number of channels
        ChannelNames        

    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = SubsystemInfo(...
                measurementTypesAvailable,...
                defaultMeasurementType,...
                nativeDataType,...               
                PhysicalChans)
            %SubsystemInfo Information about a subsystem on a device
            % SubsystemInfo(MEASUREMENTTYPESAVAILABLE,DEFAULTMEASUREMENTTYPE,NATIVEDATATYPE,NUMBEROFCHANNELSAVAILABLE)
            % A subsystem that supports a number of measurement types
            % specified by the cell array of strings
            % MEASUREMENTTYPESAVAILABLE, with a default of
            % DEFAULTMEASUREMENTTYPE, has a native data type of
            % NATIVEDATATYPE, and can support up to
            % NUMBEROFCHANNELSAVAILABLE.
            
            if ~(iscellstr(measurementTypesAvailable))
                obj.localizedError('daq:SubsystemInfo:invalidMeasurementTypes')
            end
            
            if ~(ischar(defaultMeasurementType))
                obj.localizedError('daq:SubsystemInfo:invalidDefaultMeasurement')
            end
            
            if ~ismember(defaultMeasurementType,measurementTypesAvailable)
                obj.localizedError('daq:SubsystemInfo:defaultMeasurementNotSupported')
            end
            
            if ~(ischar(nativeDataType))
                obj.localizedError('daq:SubsystemInfo:invalidNativeDataType')
            end
            
            numberOfChannelsAvailable = numel(PhysicalChans); 
            
            if ~isnumeric(numberOfChannelsAvailable) ||...
                    ~isscalar(numberOfChannelsAvailable) ||...
                    numberOfChannelsAvailable <= 0
                obj.localizedError('daq:SubsystemInfo:invalidNumberOfChannels')
            end
            
            obj.MeasurementTypesAvailable = measurementTypesAvailable;
            obj.DefaultMeasurementType = defaultMeasurementType;
            obj.NativeDataType = nativeDataType;
            obj.NumberOfChannelsAvailable = numberOfChannelsAvailable;
            obj.ChannelNames = PhysicalChans;
            obj.SubsystemTypeInfo = daq.internal.SubsystemType.Unknown;
        end
    end
    
    % Property accessor methods
    methods
        function result = get.SubsystemType(obj)
            result = char(obj.SubsystemTypeInfo);
        end
    end
    
    % Hidden read only properties
    properties(Hidden,SetAccess = protected)
        
        %SubsystemTypeInfo an enumeration describing if it is an
        %analog input, output, etc.  Should be set by the subclass.
        SubsystemTypeInfo
    end
    
    % Hidden public sealed methods, which are used as friend methods
    methods (Hidden,Sealed)
        function disp(obj)
            if any(~isvalid(obj))
                % Invalid object: use default behavior of handle class
                obj.disp@handle
                return
            end
            
            if isempty(obj)
                % Empty object: give information appropriate to no
                % subsystems
                obj.localized_fprintf('daq:SubsystemInfo:noSubsystemsAvailable');
                fprintf('\n')
                obj.dispFooter(class(obj),inputname(1),feature('HotLinks'));
                return
            end
            
            obj.getDisplayText(inputname(1));
        end
        
        function result = getDisplayText(obj, inputname)
            % Display subsystem information
            result = obj(1).getDisplayTextImpl();
            if nargin > 1
                fprintf(result);
                obj.dispFooter(class(obj),sprintf('%s(1)', inputname),feature('hotlinks'))
            end
            for iSubsystem = 2:numel(obj)
                if nargin > 1
                    fprintf(obj(iSubsystem).getDisplayTextImpl());
                    obj.dispFooter(class(obj),sprintf('%s(%d)',inputname,iSubsystem),feature('hotlinks'))
                else
                    result = [result '\n' obj(iSubsystem).getDisplayTextImpl()]; %#ok<AGROW>
                end
            end
        end
    end
    
    % Protected methods requiring implementation by a subclass
    methods (Access = protected)
        function dispText = getDisplayTextImpl(~)
            % getDisplayTextImpl Implemented by the concrete SubsystemInfo class.  Returns the
            % display for that concrete class.  Often, it calls the
            % subsystemDisplay method on the parent class to display
            % information from the base classes.
            dispText = '';
        end
        
        function dispText = subsystemDisplay(obj)
            % subsystemDisplay A display function for this class.  This allows each superclass an opportunity to
            % contribute to the subsystem display of a single concrete subsystem object.
            if obj.NumberOfChannelsAvailable == 1
                dispText = obj.getLocalizedText('daq:SubsystemInfo:dispNumChannelsSingular');
            else
                dispText = obj.getLocalizedText('daq:SubsystemInfo:dispNumChannelsPlural',...
                    num2str(obj.NumberOfChannelsAvailable));
            end
            
            if obj.NumberOfChannelsAvailable > 4
                dispText = [dispText ' ('''  obj.renderCellArrayOfStringsToString(obj.ChannelNames(1),''',''') ...
                    ''' - ''' obj.renderCellArrayOfStringsToString(obj.ChannelNames(end),''',''') ''')' ];
            else
                dispText = [dispText ' ('''  obj.renderCellArrayOfStringsToString(obj.ChannelNames,''',''') ''')'];
            end
            
            if numel(obj.MeasurementTypesAvailable) == 1
                dispText = [dispText '\n'...
                    obj.getLocalizedText('daq:SubsystemInfo:dispMeasurementTypesSingular',...
                    obj.MeasurementTypesAvailable{1})];
            else
                dispText = [dispText '\n'...
                    obj.getLocalizedText('daq:SubsystemInfo:dispMeasurementTypesPlural',...
                    obj.renderCellArrayOfStringsToString(obj.MeasurementTypesAvailable,''','''))];
            end
            suffix = obj.getSingleDispSuffixHook();
            if ~isempty(suffix)
                dispText = [dispText '\n' suffix];
            end
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        function suffixText = getSingleDispSuffixHook(obj) %#ok<MANU>
            %getSingleDispSuffixHook Vendor subclasses override to customize disp
            %suffixText = getSingleDispSuffixHook() Optional override by
            %DeviceInfo subclasses to allow them to append custom
            %information to the disp of a single DeviceInfo object.
            
            suffixText = '';
        end
    end
    
    % Protected methods this class is required to implement
    methods (Sealed, Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end
end
