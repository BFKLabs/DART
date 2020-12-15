classdef (Hidden) DSACommonChannelAttrib < handle
    %TemplateClass Example class structure
    %    TemplateClass Put your detailed info here
    
    % Copyright 2010-2013 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = DSACommonChannelAttrib
            obj.DSAPropertyChangeInProgress = false;
        end
    end
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        EnhancedAliasRejectionEnable
    end
    
    % Read only properties
    properties (Access = private)
        DSAPropertyChangeInProgress
    end
    
    % Read only properties that can be altered by a subclass
    properties (SetAccess = protected)
    end
    
    
    methods (Abstract,Access = protected)
        DSAPropertyBeingChangedImpl(obj,propertyName,newValue);
        [session] = getSession(obj)
    end
    
    % Property accessor methods
    methods
        function set.EnhancedAliasRejectionEnable(obj,value)
            try
                if obj.DSAPropertyChangeInProgress
                    obj.EnhancedAliasRejectionEnable = value;
                    return
                end
                
                if isempty(value) || ~isscalar(value) ||...
                        ~(daq.internal.isNumericNum(value) || islogical(value)) || ...
                        ((value ~= 0) && (value ~=1))
                    %Cannot derive from daq.internal.BaseClass, so
                    % call message catalog directly.
                    error(message(...
                    'nidaq:ni:EnhancedAliasRejectionEnableMustBeLogical'));
                end
                
                session = obj.getSession();
                if session.AutoSyncDSA == 1
                    %Cannot derive from daq.internal.BaseClass, so
                    % call message catalog directly.
                    error(message(...
                        'nidaq:ni:EnhancedAliasRejectionEnableReadOnlyWhenAutoSyncDSA'));
                    
                end
                
                try
                    obj.DSAPropertyChangeInProgress = true; %#ok<*MCSUP>
                    obj.DSAPropertyBeingChangedImpl('EnhancedAliasRejectionEnable',value);
                    obj.EnhancedAliasRejectionEnable = value;
                    obj.DSAPropertyChangeInProgress = false; %#ok<*MCSUP>
                catch e
                    obj.DSAPropertyChangeInProgress = false;
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
    
    methods (Access = protected)
        function DSAPropertyBeingChangedHook(obj,propertyName,newValue,session)
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
            
            try
                switch propertyName
                    case 'EnhancedAliasRejectionEnable'
                        taskHandle = session.getUnreservedTaskHandle(obj.GroupName);
                        [status] = daq.ni.NIDAQmx.DAQmxSetAIEnhancedAliasRejectionEnable(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            uint32(newValue));
                        daq.ni.utility.throwOrWarnOnStatus(status);                        
                end
            catch e
                switch e.identifier
                    case {'nidaq:ni:err200077','nidaq:ni:err200452'}
                        % Cannot derive from daq.internal.BaseClass, so
                        % call message catalog directly.
                        error(message('nidaq:ni:deviceDoesNotSupport',propertyName,newValueChar))
                    otherwise
                        rethrow(e)
                end
            end
            
        end
    end
    methods (Sealed, Access = protected)
        function captureDSACommonChannelAttribFromNIDAQmx(obj,taskHandle)
            
            obj.DSAPropertyChangeInProgress = true;
            
            % Capture the ADC timing mode
            [status,aliasmode] = daq.ni.NIDAQmx.DAQmxGetAIEnhancedAliasRejectionEnable(...
                taskHandle,...
                obj.PhysicalChannel,... % channel
                uint32(0));              % data
            

            if status == daq.ni.NIDAQmx.DAQmxErrorAttributeNotSupportedInTaskContext
                % G903703
                % We have found DSA devices that do not support Enhanced
                % Alias-Rejection (NI USB-4432)
                % If this particular error comes up during initialization,
                % ignore it
            else
                % If a different error comes up, process it
                daq.ni.utility.throwOrWarnOnStatus(status);
            end

            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.EnhancedAliasRejectionEnable = aliasmode;
            end
                       
            obj.DSAPropertyChangeInProgress = false;

        end
    end
    
    methods(Hidden)
        % Auto sync property changes the enhanced alias
        % rejection mode for the channel objects.             
        function onDSATaskRecreationHook(obj,taskHandle)
            session = obj.getSession();
            if session.AutoSyncDSA
                try
                    obj.captureDSACommonChannelAttribFromNIDAQmx(taskHandle);
                catch e
                   session.handleAutoSyncDSAErrors(e);
                end
            end
        end
        
    end
end
