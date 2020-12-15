classdef (Hidden) Channel < daq.internal.BaseClass & daq.internal.UserDeleteDisabled
    %Channel All settings & operations for a channel added to a session.
    %    This class is specialized for each class of channel that is
    %    possible.  Vendors further specialize those to implement
    %    additional behaviors.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %Name An arbitrary string defined by the user to help to
        %identify the channel
        Name
    end
    
    % Read only properties
    properties(SetAccess = private)
        %ID A vendor defined hardware identifier of the
        %channel.  It should correspond to the terminal ID on the physical device.
        ID
        
        %Device A daq.Device object representing the device that this
        %channel is part of.
        Device
        
        %MeasurementType Measurement type
        MeasurementType        
    end
    
    properties(Hidden)
        %OnDemandOperationsSupported A double representing if on demand
        %operations like inputSingleScan/outputSingleScan are supported by
        %the channel.
        OnDemandOperationsSupported
        
        isGroup
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = Channel(subsystemType,session,deviceInfo,id)
            %Channel All settings & operations for a channel added to a session.
            %    Channel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    channel with a subsystem type SUBSYSTEMTYPE of class
            %    daq.internal.SubsystemType, attached to SESSION of class
            %    daq.Session, on a device DEVICEINFO of type
            %    daq.DeviceInfo, with a channel identifier string of ID.
            
            obj.BlockPropertyNotificationDuringInit = true;
            obj.Name = '';
            
            if ~isa(subsystemType,'daq.internal.SubsystemType')
                obj.localizedError('daq:Channel:invalidSubsystemType')
            end
            if ~isa(session,'daq.Session')
                obj.localizedError('daq:Channel:invalidSession')
            end
            if ~isa(deviceInfo,'daq.DeviceInfo')
                obj.localizedError('daq:Channel:invalidDevice')
            end
            
            if iscell(id) && subsystemType == daq.internal.SubsystemType.DigitalIO
                obj.ID = sprintf('dg%d', daq.Channel.getNextDigitalGroupIndex(false));
                obj.isGroup = true;
            elseif ischar(id)
                obj.ID = id;
                obj.isGroup = false;
            else
                obj.localizedError('daq:Channel:invalidTerminalID')
            end
            
            obj.SubsystemType = subsystemType;
            obj.Session = session;
            
            % Record the UniqueHardwareID.  Hardware is tracked using a
            % unique, vendor defined string.  This ID should uniquely
            % identify a specific piece of hardware, such as the serial
            % number.
            obj.UniqueHardwareID = deviceInfo.UniqueHardwareID;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Property access methods
    methods
        function deviceInfo = get.Device(obj)
            %A reference to the DeviceInfo object associated with the device
            %that this channel is on.  However, this is not stored, but
            %found by the getter via a lookup of UniqueHardwareID.  This
            %allows tracking of hardware through renames and unplug/plug
            %cycles.

            % g873066,873097,885613: Fixed LXE incompatibility warnings
            HardwareInfo = daq.HardwareInfo.getInstance(); 
            deviceInfo = HardwareInfo.Devices.locateByUniqueID(obj.Session.Vendor.ID,obj.UniqueHardwareID);
        end
        
        function measurementType = get.MeasurementType(obj)
            measurementType = obj.getMeasurementTypeDisplayHook();
        end
        
        function set.Name(obj,newValue)
            try
                if ~ischar(newValue)
                    obj.localizedError('daq:Channel:invalidName')
                end
                
                % Notify session of name change
                obj.channelPropertyBeingChanged('Name',newValue)
                
                obj.Name = newValue;
            catch e
                % Rethrow any errors as caller, removing the long stack of
                % errors -- capture the full exception in the cause field
                % if FullDebug option is set.
                if daq.internal.getOptions().FullDebug
                    rethrow(e);
                end
                e.throwAsCaller()
            end
        end
    end
    
    % Hidden read only properties
    properties(Hidden,SetAccess = private)
        SubsystemType
    end
    
    % Hidden public sealed methods, which are used as friend methods
    methods (Sealed, Hidden)
        function result = countInputChannels(obj)
            result = 0;
            for iObj = 1:numel(obj)
                if isa(obj(iObj),'daq.AnalogInputChannel') ||...
                   isa(obj(iObj),'daq.AudioInputChannel') ||...
                   isa(obj(iObj),'daq.CounterInputChannel') ||...
                   (isa(obj(iObj),'daq.DigitalChannel') && strcmp(obj(iObj).Direction,'Input'))
                    result = result + 1;
                end
            end
        end
        
        function result = countOutputChannels(obj)
            result = 0;
            for iObj = 1:numel(obj)
                % Note: Counter Output channels are not included in this count
                % because they do not support outputSingleScan or queueOutputData
                if isa(obj(iObj),'daq.AnalogOutputChannel') ||...
                   isa(obj(iObj),'daq.AudioOutputChannel') ||...
                   (isa(obj(iObj),'daq.DigitalChannel') && strcmp(obj(iObj).Direction,'Output'))
                    result = result + 1;
                end
            end
        end
        
        function result = countCounterInputChannels(obj)
            result = obj.countChannelsOfType('daq.CounterInputChannel');
        end
		
        function result = countAudioInputChannels(obj)
            result = obj.countChannelsOfType('daq.AudioInputChannel');
        end

        function result = countAudioOutputChannels(obj)
            result = obj.countChannelsOfType('daq.AudioOutputChannel');
        end
        
        function result = getSubsystem(obj)
            % getSubsystem returns the subsystem from the device associated
            % with this channel.  If the device has been removed, it
            % returns empty [].
            result = daq.SubsystemInfo.empty;
            
            for iObj = 1:numel(obj)
                device = obj(iObj).Device;
                if isempty(device)
                    % Device can be empty, in the event of a device
                    % removal.  Skip this device
                    continue
                end
                result(end+1) = device.getSubsystem(obj(iObj).SubsystemType); %#ok<AGROW>
            end
        end
        
        function errorIfNotReadyToStart(obj)
            % errorIfNotReadyToStart is called when the session is prepared
            % to give channels an opportunity to error if they are not
            % ready to run, or have invalid settings.
            for iObj = 1:numel(obj)
                obj(iObj).errorIfNotReadyToStartHook();
            end
        end
        
        function errorIfOutOfRange(obj, dataToOutput)
            % errorIfOutOfRange is called to check that data on each
            % channel is not below or above the Range for that channel.
            
            % If there is no data or it is not numeric don't try to check
            % the range here. It will be dealt with in a more appropriate
            % place.
            if isempty(dataToOutput) || ~isnumeric(dataToOutput)
                return
            end
            
            % Take care to match up the dataToOutput with the Output
            % channels. It is possible that there are Input channels mixed
            % in so we must skip over them.
            dataCol = 1;
            for chanNum = 1:length(obj)
                isAO = isa(obj(chanNum), 'daq.AnalogOutputChannel');
                isDO = isa(obj(chanNum), 'daq.DigitalChannel') &&...
                    strcmp(obj(chanNum).Direction,char(daq.Direction.Output));
                isAudO = isa(obj(chanNum), 'daq.AudioOutputChannel');
                
                
                if ~isAO && ~isDO && ~isAudO
                    continue
                end
                
                if isAO || isAudO
                    if max(dataToOutput(:, dataCol)) > obj(chanNum).Range.Max || ...
                            min(dataToOutput(:, dataCol)) < obj(chanNum).Range.Min
                        obj.localizedError('daq:Channel:dataOutOfRange',...
                            num2str(chanNum), ...
                            char(obj(chanNum).Range))
                    end
                end
                
                % Advance to the next data column now that we've dealt with
                % this output channel.
                dataCol = dataCol + 1;
            end
        end
    end
    
    methods (Hidden)
        function deleteRemovedChannel(obj)
            delete(obj);
        end
    end
    
    methods (Hidden, Static)
        % Returns a parsed cell array of channels
        function [result] = parseChannelsHook(channels)
			% The DigitalChannel overrides this hook to provide custom
            % parsing of dio channels.
            if iscell(channels)
                result = channels;
            else
                if daq.internal.isNumericNum(channels)
                    result = num2cell(channels);
                else
                    result = {channels};
                end
            end
        end
    end
    
    % Hidden Sealed methods, so that they don't show up in methods()
    methods(Hidden,Sealed)
        function disp(obj)
            %disp display session information
            
            % In some contexts, such as publishing, you cannot use
            % hyperlinks.  If hotlinks is true, then you can.
            hotlinks = feature('hotlinks');
            
            if any(~isvalid(obj)) || isempty(obj)
                % Invalid object: use default behavior of handle class
                obj.disp@handle
                return
            end
            
            if numel(obj) == 1
                % Single object -- do detailed display
                
                % Title
                obj.localized_fprintf('daq:Channel:dispTitle',...
                    obj.getChannelDescriptionHook(),...
                    obj.ID,...
                    obj.Device.ID);
                fprintf('\n')
                get(obj)
                
                % Check to see if the Vendor implementation has defined
                % additional information to append to the display
                suffixText = getSingleDispSuffixHook(obj);
                if ~isempty(suffixText)
                    fprintf('\n');
                    fprintf(suffixText);
                end
                fprintf('\n')
                obj.dispFooter(class(obj),inputname(1),hotlinks)
            else
                % It's a vector of objects:  Show as table
                fprintf(obj.getDisplayText())
            end
        end
        
        function [result] = getDisplayText(obj)
            if isempty(obj)
                result = obj.getLocalizedText('daq:Channel:dispTableHeaderNoChannels');
                result = [result '\n'];
                return
            end
            
            result = obj.getLocalizedText('daq:Channel:dispTableHeader',num2str(numel(obj)));
            result = [result '\n'];
            table = internal.DispTable();
            table.Indent = daq.internal.BaseClass.StandardIndent;
            table.addColumn(obj.getLocalizedText('daq:Channel:dispTableIndexColumn'));
            table.addColumn(obj.getLocalizedText('daq:Channel:dispTableTypeColumn'));
            table.addColumn(obj.getLocalizedText('daq:Channel:dispTableDeviceColumn'));
            table.addColumn(obj.getLocalizedText('daq:Channel:dispTableChannelColumn'));
            table.addColumn(obj.getLocalizedText('daq:Channel:dispTableMeasurementTypeColumn'));
            table.addColumn(obj.getLocalizedText('daq:Channel:dispTableRangeColumn'));
            table.addColumn(obj.getLocalizedText('daq:Channel:dispTableNameColumn'));
            for iObj=1:numel(obj)
                channelDesc = '';
                if isa(obj(iObj), 'daq.DigitalChannel')
                    if obj(iObj).GroupChannelCount > 1
                        channelDesc = sprintf(' (%d lines)', obj(iObj).GroupChannelCount);
                    end
                end
                table.addRow(iObj,...
                    obj(iObj).SubsystemType.getShortName(),...
                    obj(iObj).Device.ID,...
                    [obj(iObj).ID channelDesc],...
                    obj(iObj).getChannelInfoDisplayHook(),...
                    obj(iObj).getRangeDisplayHook(),...
                    obj(iObj).Name);
            end
            result = [result table.getDisplayText()];
        end
        
        function [terminal] = abbreviateTerminalName(obj, terminalName) %#ok<MANU>
            findToken = strfind(terminalName, '/');
            if ~isempty(findToken)
                terminal = terminalName(findToken(end) + 1 : end);
            else
                terminal = terminalName;
            end
        end
    end
    
    % Protected properties for use by a subclass
    properties(GetAccess=protected,SetAccess=protected)
        BlockPropertyNotificationDuringInit
    end
    
    % Protected read only properties for use by a subclass
    properties(GetAccess=protected,SetAccess=private)
        %Session The daq.Session object that this channel is part of.
        Session
    end
    
    % Protected template methods with optional implementation by a subclass
    methods(Access = protected)
        function suffixText = getSingleDispSuffixHook(obj) %#ok<MANU>
            %getSingleDispSuffixImpl Subclasses override to customize disp
            %suffixText = getSingleDispSuffixImpl() Optional override by
            %Session subclasses to allow them to append custom
            %information to the disp of a single Session object.
            
            suffixText = '';
        end
        
        function channelPropertyBeingChangedHook(obj,propertyName,newValue) %#ok<INUSD,MANU>
            % channelPropertyBeingChangedHook React to change in channel property.
            %
            % Provides the vendor the opportunity to react to changes in
            % channel properties.  Note that releaseHook() will be called
            % before this if needed.
            %
            % channelPropertyBeingChangedHook(PROPERTYNAME,NEWVALUE)
            % is called before property changes occur.  The vendor
            % implementation may throw an error to prevent the change, or
            % update their corresponding hardware session, if appropriate.
            % PROPERTYNAME is the name of the property to change and
            % NEWVALUE is the new value the property will have if this
            % function returns normally.
            %
            %Default implementation is to do nothing.
        end
        
        function errorIfNotReadyToStartHook(obj) %#ok<MANU>
            % errorIfNotReadyToStartHook Error if channel property is
            % invalid
            %
            % Provides the channel the opportunity to validate that all
            % settings are appropriate for an operation.
            %
            % errorIfNotReadyToStartHook() is called as part of prepare().
            % The vendor implementation may throw an error to prevent the
            % operation from going forward.
            %
            %Default implementation is to do nothing.
        end

        function rangeDisplayText = getRangeDisplayHook(obj) %#ok<MANU>
            % getRangeDisplayHook A function that returns the string to
            % display current range information in the display operation
            rangeDisplayText = 'n/a';
        end
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'n/a';
        end
        
        function channelInfoText = getChannelInfoDisplayHook(obj)
            % getChannelInfoDisplayHook A function that returns the string
            % to display channel information in the session display
            % operation
            channelInfoText = obj.getMeasurementTypeDisplayHook();
        end
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionHook A function that returns the string to
            % display the measurement type in the channel display operation
            channelDescriptionText = 'channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function channelPropertyBeingChanged(obj,propertyName,newValue)
            % Notify the Vendor implementation that a
            % channel parameter is attempting to be changed.
            
            % If we're initializing the channel, don't send updates
            if obj.BlockPropertyNotificationDuringInit
                return
            end
            
            
            % Check with the session that it is OK to change parameters.
            obj.Session.errorIfParameterChangeNotOK()
            
            % Call the vendor implementation to implement the property
            % change
            obj.channelPropertyBeingChangedHook(propertyName,newValue);
        end
    end
    
    % Private properties
    properties(SetAccess = private, GetAccess = private)
        %UniqueHardwareID Hardware is tracked using a unique, vendor
        %defined string.  This ID should uniquely identify a specific piece
        %of hardware, such as the serial number.
        UniqueHardwareID
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            obj.Session = [];
            daq.Channel.getNextDigitalGroupIndex(true); % reset digital group id to 'dg1'
            if ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
    end
    
    % Private methods
    methods (Sealed,Hidden)
        function result = countChannelsOfType(obj,type)
            result = 0;
            for iObj = 1:numel(obj)
                % Today, there is only one type of output channel.
                % Someday, there may be more, and we may choose another
                % mechanism.
                if isa(obj(iObj),type)
                    result = result + 1;
                end
            end
        end
    end
    
    methods(Static, Access = private)
        function [result] = getNextDigitalGroupIndex(reset)
			% Digital group id is 1 indexed (i.e. starts with 'dg1')
            persistent nextDigitalGroupIndex;
            
            % Initialization
            if isempty(nextDigitalGroupIndex)
                nextDigitalGroupIndex = 0;
            end

			% If reset = true, set internal count to 0 so next call to get
			% the digital group index gets a 1 ('dg1')
            if reset
                nextDigitalGroupIndex = 0;
                result = nextDigitalGroupIndex;
                return;
            end
            
            nextDigitalGroupIndex = nextDigitalGroupIndex + 1;
            result = nextDigitalGroupIndex;
        end
    end
end
