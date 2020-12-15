classdef (Hidden) AnalogChannel < daq.Channel
    %AnalogChannel All settings & operations for an analog channel added to a session.
    %    This class is specialized for each class of analog channel that is
    %    possible.  Vendors further specialize those to implement
    %    additional behaviors.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %Range The current range of the channel
        Range;
    end
       
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = AnalogChannel(subsystemType,session,deviceInfo,id,supportedRanges)
            %AnalogChannel All settings & operations for an analog channel added to a session.
            %    AnalogChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID,SUPPORTEDRANGES) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel), with an vector of ranges
            %    SUPPORTEDRANGES of type daq.Range.
            
            obj@daq.Channel(subsystemType,session,deviceInfo,id);
            
            % Capture the supported ranges
            if ~isa(supportedRanges,'daq.Range')
                obj.localizedError('daq:Channel:invalidPossibleRanges')
            end
            obj.SupportedRanges = supportedRanges;

            % Initialize range to the widest span [Max - Min] by default
            [~,widestSpanIndex] = max([supportedRanges.Max] - [supportedRanges.Min]);
            
            obj.BlockPropertyNotificationDuringInit = true;
            obj.Range = supportedRanges(widestSpanIndex);
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    % Property access methods
    methods
        function set.Range(obj,value)
                try
                    obj.Range = setRangeHook(obj,value);
                catch e
                    % Rethrow any errors as caller, removing the long stack of
                    % errors -- capture the full exception in the cause field
                    % if FullDebug option is set.
                    if daq.internal.getOptions().FullDebug
                        rethrow(e)
                    end
                    e.throwAsCaller()
                end
        end
    end

    % Protected methods this class is required to implement
    methods (Access = protected)
        function rangeDisplayText = getRangeDisplayHook(obj) 
        % getRangeDisplayHook A function that returns the string to
        % display current range information in the display operation
            rangeDisplayText = char(obj.Range);
        end
        
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if  ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access=protected)
        function newRange = setRangeHook(obj,value)
            %setRangeHook Subclasses override to customize behavior
            %associated with setting the Range of the channel
            %
            % Default implementation checks the range against the list of
            % valid ranges.
            if ~isa(value,'daq.Range')
                if isnumeric(value) && all(size(value) == [1 2])
                    % If they pass in a 1x2 numeric, create a Range object
                    % with the same units.
                    value = daq.Range(value(1),value(2),obj.Range.Units);
                else
                    obj.localizedError('daq:Channel:invalidRange')
                end
            end

            try
                closestRange = value.locateClosestRange(obj.SupportedRanges); 
            catch e
                if strcmp(e.identifier,'daq:general:noRangeFound')
                    % Recast the error to a more appropriate one for this
                    % scenario
                    obj.localizedError('daq:Channel:requestedRangeNotSupported')
                else
                    rethrow(e)
                end
            end

            % Notify session of range change
            obj.channelPropertyBeingChanged('Range',closestRange)

            % If the range chosen is more than 1% different than the
            % requested range, fire a warning.
            spanValue = value.Max - value.Min;
            diffPercentage = abs((closestRange.Max - closestRange.Min) - spanValue) * 100 / spanValue;
            if diffPercentage > obj.WarnOnRangeVariancePercentage
                obj.localizedWarning('daq:Channel:closestRangeChosen',...
                    char(value),...
                    char(closestRange))
            end
            newRange = closestRange;
        end
    end

    % Internal constants
    properties(Constant, GetAccess = private)
        % When range is set, the value that is selected is not always the
        % same as the one requested.  When the span of selected range is
        % more than X percent different from the requested, fire a warning.
        WarnOnRangeVariancePercentage = 1;
    end
    
    % Protected read-only properties
    properties (GetAccess = protected,SetAccess = protected)
        % An array of supported ranges for the channel
        SupportedRanges
    end

end
