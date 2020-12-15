classdef (Hidden) AnalogOutputCurrentChannel < daq.AnalogOutputChannel
    %AnalogOutputCurrentChannel All settings & operations for an analog output current channel added to a session.
    %    Vendors can further specialize this to implement
    %    additional behaviors.
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.3 $  $Date: 2011/11/07 17:28:12 $
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    properties
        % TerminalConfig The current Terminal Configuration type (single ended/differential)
        TerminalConfig;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogOutputCurrentChannel(session,deviceInfo,id)
            %AnalogOutputCurrentChannel All settings & operations for an analog output voltage channel added to a session.
            %    AnalogOutputCurrentChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Voltage channels can only use Volts as a range
            obj@daq.AnalogOutputChannel(session,deviceInfo,id,'A');
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'Current';
        end
        
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %TerminalConfigInfo The current output type (single ended/differential) as an
        %enumeration
        TerminalConfigInfo;
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'analog output current channel';
        end
    end
    
    methods
        function set.TerminalConfigInfo(obj,value)
            try
                if obj.PropertyChangeInProgress
                    obj.TerminalConfigInfo = value;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newValue = daq.TerminalConfig.setValue(value);
                    obj.channelPropertyBeingChanged('TerminalConfigInfo',newValue)
                    % Keep the hidden and visible properties in sync
                    obj.TerminalConfigInfo = newValue;
                    obj.TerminalConfig = char(newValue);
                    obj.PropertyChangeInProgress = false;
                catch e
                    obj.PropertyChangeInProgress = false;
                    rethrow(e)
                end
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
        
        function set.TerminalConfig(obj,value)
            try
                if obj.PropertyChangeInProgress
                    obj.TerminalConfig = value;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newValue = daq.TerminalConfig.setValue(value);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('TerminalConfigInfo',newValue)
                    % Keep the hidden and visible properties in sync
                    obj.TerminalConfig = char(newValue);
                    obj.TerminalConfigInfo = newValue;
                    obj.PropertyChangeInProgress = false;
                catch e
                    obj.PropertyChangeInProgress = false;
                    rethrow(e)
                end
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
end
