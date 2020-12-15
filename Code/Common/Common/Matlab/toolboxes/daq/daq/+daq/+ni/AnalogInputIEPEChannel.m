classdef (Hidden) AnalogInputIEPEChannel < daq.ni.AnalogInputVoltageIEPECurrentExcitationChannel
    %AnalogInputIEPEChannel All settings & operations for an NI analog input IEPE channel.
    
    % Copyright 2010-2013 The MathWorks, Inc.
    %
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = AnalogInputIEPEChannel(session,deviceInfo,channelID)
            %AnalogInputIEPEChannel All settings & operations for
            %an analog input IEPE channel added to a session.
            %    AnalogInputIEPEChannel(SUBSYSTEMTYPE,SESSION,DEVICEINFO,ID) Create a
            %    analog channel with SUBSYSTEMTYPE, SESSION, DEVICEINFO,
            %    and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.ni.AnalogInputVoltageIEPECurrentExcitationChannel(session,deviceInfo,channelID);
            
            % NI-DAQmx refers to channels by "<device>/<channelID>"
            obj.PhysicalChannel = [deviceInfo.ID '/' channelID];
            
            % Get the channel group name.
            obj.GroupName = obj.getGroupNameHook();
            
            % Set channel defaults
            obj.BlockPropertyNotificationDuringInit = true;
            obj.PropertyChangeInProgress = true;
            
            obj.OnDemandOperationsSupported = ...
                deviceInfo.getSubsystem(daq.internal.SubsystemType.AnalogInput).OnDemandOperationsSupported;
            
            obj.PropertyChangeInProgress = false;
            obj.BlockPropertyNotificationDuringInit = false;
        end
    end
    
    methods
        
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function configureTask(obj,taskHandle)
            obj.createChannel(taskHandle,daq.ni.utility.DAQToNI(obj.TerminalConfigInfo))
            
            [status] = daq.ni.NIDAQmx.DAQmxSetAICoupling(taskHandle,obj.PhysicalChannel,daq.ni.utility.DAQToNI(obj.CouplingInfo));
            daq.ni.utility.throwOrWarnOnStatus(status);
        end
        
        function createChannelAndCaptureParameters(obj,taskHandle)
            obj.createChannelFirstTime(taskHandle)
            obj.captureAnalogInputIEPEParametersFromNIDAQmx(taskHandle)
        end
        
        function setExcitationSourceHook(obj,~)
            obj.localizedError('nidaq:ni:iepeExcitationSourceIsReadOnly');
        end        
       
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Access = protected)
        
        function [groupName] = getGroupNameHook(obj)
            % Define the channel group name for this channel.
            %
            % The default implementation is to set GroupName to
            % "ai/<DeviceID>" which causes all analog input channels from a
            % device to be grouped together.
            groupName = ['ai/' obj.Device.ID];
        end
        
        function measurementTypeDisplayText = getMeasurementTypeDisplayHook(obj) %#ok<MANU>
            % getMeasurementTypeDisplayHook A function that returns the string to
            % display the measurement type in the display operation
            measurementTypeDisplayText = 'IEPE';
        end
        
        function channelPropertyBeingChangedHook(obj,propertyName,newValue)
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
            channelPropertyBeingChangedHook@daq.ni.AnalogInputVoltageIEPECurrentExcitationChannel(obj,propertyName,newValue);            
        end
        
        function createChannelFirstTime(obj,taskHandle)
            obj.createChannel(taskHandle,daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default);
        end
    end
    
    % Friends
    methods(Hidden)
        function channelDescriptionText = getChannelDescriptionHook(obj) %#ok<MANU>
            % getChannelDescriptionText A function that returns the string
            % to display the channel description in the channel display
            % operation
            channelDescriptionText = 'analog input IEPE channel';
        end
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function captureAnalogInputIEPEParametersFromNIDAQmx(obj,taskHandle)
            % Capture the input type, get it from NI-DAQmx
            [status,AITermCfg] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
                obj.PhysicalChannel, int32(0));
            % Check the status after insuring failure not caused by
            % need to set the sample rate first.
            
            % G496133 Some devices require that the sample rate be set
            % before other operations. This will be indicated by the
            % status of the attempt to get the AITermCfg above.
            if status == daq.ni.NIDAQmx.DAQmxErrorSampClkRateMustBeSpecd
                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                    taskHandle,...
                    obj.Device.Subsystems.RateLimit(1));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status,AITermCfg] = daq.ni.NIDAQmx.DAQmxGetAITermCfg(taskHandle,...
                    obj.PhysicalChannel, int32(0));
                % Check status outside if block
            end
            daq.ni.utility.throwOrWarnOnStatus(status);
            obj.TerminalConfig = daq.ni.utility.NIToDAQ(AITermCfg);
            
            % We don't know the Coupling: get it from NI-DAQmx
            [status,AICoupling] = daq.ni.NIDAQmx.DAQmxGetAICoupling(...
                taskHandle,...
                obj.PhysicalChannel,...
                int32(0));
            if status == daq.ni.NIDAQmx.DAQmxSuccess
                obj.Coupling = daq.ni.utility.NIToDAQ(AICoupling);
            end            

        end
    end
    
    methods (Static, Hidden)
        function [isSupported] = detectIfSupported(device,knownGoodVoltageRange, knownGoodRateLimit)
            isSupported = false;
            
            try
                [status,taskHandle] = daq.ni.NIDAQmx.DAQmxCreateTask (char(0),uint64(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan (...
                    taskHandle,...                                  % The task handle
                    sprintf('%s/ai0',device),...                    % physicalChannel
                    char(0),...                                     % nameToAssignToChannel
                    daq.ni.NIDAQmx.DAQmx_Val_Cfg_Default,...        % terminalConfig
                    knownGoodVoltageRange.Min,...                          % minVal
                    knownGoodVoltageRange.Max,...                          % maxVal
                    daq.ni.NIDAQmx.DAQmx_Val_Volts,...              % units
                    char(0));                                       % customScaleName
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                [status] = daq.ni.NIDAQmx.DAQmxSetSampClkRate(...
                    taskHandle,...
                    knownGoodRateLimit.Min);
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                % Some devices require that the coupling be set to AC,
                % before we can configure the excitation source.                
                [status] = daq.ni.NIDAQmx.DAQmxSetAICoupling(...
                    taskHandle,...
                    sprintf('%s/ai0',device),...
                    daq.ni.NIDAQmx.DAQmx_Val_AC);                
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                % Try to set the excitation source to 'Internal'
                [status] = daq.ni.NIDAQmx.DAQmxSetAIExcitSrc(...
                    taskHandle,...          % taskHandle
                    sprintf('%s/ai0',device),... % channel
                    daq.ni.NIDAQmx.DAQmx_Val_Internal);
                daq.ni.utility.throwOrWarnOnStatus(status);
                [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIExcitSrc(...
                    taskHandle,...          % taskHandle
                    sprintf('%s/ai0',device),... % channel
                    int32(0));
                daq.ni.utility.throwOrWarnOnStatus(status);
                
                if readValue ~= daq.ni.NIDAQmx.DAQmx_Val_Internal
                    return;
                end
                
                % Try to set the excitation value to 2mA. This is the
                % minimum requirement for IEPE.
                [~] = daq.ni.NIDAQmx.DAQmxSetAIExcitVal(...
                    taskHandle,...          % taskHandle
                    sprintf('%s/ai0',device),... % channel
                    .002);
                
                [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIExcitVal(...
                    taskHandle,...          % taskHandle
                    sprintf('%s/ai0',device),... % channel
                    double(0));
                
                if status ~= daq.ni.NIDAQmx.DAQmxSuccess
                    % Some devices like NI 9232 support only 4mA and error
                    % out if 2mA is set as Excitation current. If 2mA
                    % fails, try with 4mA
                    [~] = daq.ni.NIDAQmx.DAQmxSetAIExcitVal(...
                        taskHandle,...          % taskHandle
                        sprintf('%s/ai0',device),... % channel
                        .004);
                    
                    [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAIExcitVal(...
                        taskHandle,...          % taskHandle
                        sprintf('%s/ai0',device),... % channel
                        double(0));
                end
                
                if readValue < 0.002
                    return;
                end
                
                daq.ni.utility.throwOrWarnOnStatus(status);
                isSupported = true;                
            catch  %#ok<CTCH>
                % Any error is failure
            end
            
            [~] = daq.ni.NIDAQmx.DAQmxClearTask(taskHandle);
        end
    end
    
    % Private methods
    methods (Access = protected)
        function createChannel(obj,taskHandle,niTerminalConfig)
            % create a voltage channel
            [status] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan (...
                taskHandle,...                                  % The task handle
                obj.PhysicalChannel,...                         % physicalChannel
                char(0),...                                     % nameToAssignToChannel
                niTerminalConfig,...                            % terminalConfig
                obj.Range.Min,...                               % minVal
                obj.Range.Max,...                               % maxVal
                daq.ni.NIDAQmx.DAQmx_Val_Volts,...              % units
                char(0));                                       % customScaleName
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            % configure coupling 
            [status] = daq.ni.NIDAQmx.DAQmxSetAICoupling(...
                    taskHandle,...
                    obj.PhysicalChannel,...
                    daq.ni.NIDAQmx.DAQmx_Val_AC);                
            daq.ni.utility.throwOrWarnOnStatus(status);
            
             % configure internal excitation            
            [status] = daq.ni.NIDAQmx.DAQmxSetAIExcitSrc(...
                taskHandle,...          % taskHandle
                obj.PhysicalChannel,... % channel
                daq.ni.NIDAQmx.DAQmx_Val_Internal);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
            [status] = daq.ni.NIDAQmx.DAQmxSetAIExcitVal(...
                taskHandle,...          % taskHandle
                obj.PhysicalChannel,... % channel
                obj.ExcitationCurrent);
            daq.ni.utility.throwOrWarnOnStatus(status);
            
        end
    end
end

