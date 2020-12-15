classdef (Hidden) AnalogInputCurrentChannel < daq.AnalogInputChannel
    %AnalogInputCurrentChannel All settings & operations for an analog input voltage channel added to a session.
    %    Vendors can further specialize this to implement
    %    additional behaviors.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    %   
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        %Coupling The current coupling mode of the channel
        Coupling;
        
        %TerminalConfig The current input type (single ended/differential)
        TerminalConfig;
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputCurrentChannel(session,deviceInfo,id)
            %AnalogInputCurrentChannel All settings & operations for an analog input voltage channel added to a session.
            %    AnalogInputCurrentChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)

            % Current channels can only use Amps as a range
            obj@daq.AnalogInputChannel(session,deviceInfo,id,'A');
            
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = true;
            obj.CouplingInfo = daq.Coupling.DC;
            obj.TerminalConfigInfo = daq.TerminalConfig.Differential;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
       
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
    end
    
    % Overrides
    methods (Access = protected)
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'Current';
        end
    end
    
    % Hidden properties
    properties(Hidden)
        %CouplingInfo The current coupling mode of the channel as an
        %enumeration
        CouplingInfo
        
        %InputType and TerminalConfigInfo The current input type (single
        %ended/differential) as an enumeration
        InputType
        TerminalConfigInfo
    end 
     
    % Property access methods
    methods
        function set.CouplingInfo(obj,value)
            try
                if obj.PropertyChangeInProgress
                    obj.CouplingInfo = value;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newValue = daq.Coupling.setValue(value);
                    obj.channelPropertyBeingChanged('CouplingInfo',newValue)
                    % Keep the hidden and visible properties in sync
                    obj.CouplingInfo = newValue;
                    obj.Coupling = char(newValue);
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
                    rethrow(e);
                end
                e.throwAsCaller()
            end
        end
        
        function set.Coupling(obj,value)
            try
                if obj.PropertyChangeInProgress
                    obj.Coupling = value;
                    return
                end
                try
                    obj.PropertyChangeInProgress = true;
                    newValue = daq.Coupling.setValue(value);
                    % Really, we only change the underlying hidden property
                    % with the enumeration -- and we only report that change
                    obj.channelPropertyBeingChanged('CouplingInfo',newValue)
                    % Keep the hidden and visible properties in sync
                    obj.Coupling = char(newValue);
                    obj.CouplingInfo = newValue;
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
                    obj.InputType = char(newValue);
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
                    obj.InputType = char(newValue);
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
        
        function set.InputType(obj,value)
      try
                if obj.PropertyChangeInProgress
                    obj.InputType = value;
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
                    obj.InputType = char(newValue);
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
    
    % Overrides
    methods (Access = protected)
        function channelInfoDisplayText = getChannelInfoDisplayHook(obj)
            % getChannelInfoDisplayHook A function that returns the string to
            % display the channel measurement type and other info in
            % the session display table
            channelInfoDisplayText = sprintf('%s (%s)', ...
                obj.getMeasurementTypeDisplayHook(), ...
                obj.TerminalConfigInfo.getShortName());
        end
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'analog input current channel';
        end
    end
end
