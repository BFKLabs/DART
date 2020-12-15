classdef (Hidden) AsyncIOInputChannel < daq.internal.BaseClass
    %AsyncIOInputChannel AsyncIO Input Channel
    
    % Copyright 2012 The MathWorks, Inc.
    
    %% private properties
    properties(Access = private)
        PluginDir;
        ConverterPluginPath;
        DevicePluginPath;
        AsyncIOChannel;
        StreamLimits;
        DataWrittenListener;
        CustomListener;
        ChannelOptions;
        Session;
        ChannelGroup;
    end
    
    %% constructor/destructor
    methods
        function obj = AsyncIOInputChannel(session, channelGroup, pluginName)
            % Initialize properties
            obj.Session = session;
            obj.ChannelGroup = channelGroup;
            
            obj.DevicePluginPath = '';
            obj.AsyncIOChannel = [];
            obj.StreamLimits = [Inf Inf];
            obj.DataWrittenListener = [];
            obj.CustomListener = [];
            
            % Create the AsyncIO Channel
			p = mfilename('fullpath');
            obj.PluginDir = fullfile(p, '..\..\..\', 'bin', computer('arch'));
            obj.ConverterPluginPath = fullfile(obj.PluginDir, 'ni', 'daqmlconverter');
            obj.DevicePluginPath = fullfile(obj.PluginDir, 'ni', pluginName);
            try
                obj.AsyncIOChannel = asyncio.Channel(obj.DevicePluginPath, ...
                    obj.ConverterPluginPath, ...
                    [], ...
                    obj.StreamLimits);
            catch e
                if strcmpi(e.identifier, 'asyncio:Channel:couldNotLoadConverter')
                    obj.Session.localizedError('nidaq:ni:daqmlconverterNotFound',...
                            strrep(strcat(obj.ConverterPluginPath,'.dll'), '\', '\\'));
                elseif strcmpi(e.identifier, 'asyncio:Channel:couldNotLoadDevice')
                    obj.Session.localizedError('nidaq:ni:mwnidaqmxNotFound',...
                            strrep(strcat(obj.DevicePluginPath,'.dll'), '\', '\\'));
                else
                    obj.Session.localizedError('nidaq:ni:mwnidaqmxPluginNotLoaded', pluginName);
                end
            end
            
            % Register listener for DataWritten event
            obj.DataWrittenListener = addlistener(obj.AsyncIOChannel.InputStream,...
                'DataWritten', ...
                @obj.handleDataAvailable);
            
            % Add custom event listener for the following events
            %   DoneEvent               : Task done
            %   DataMissedEvent         : Data Missed
            %   NIDAQmxDriverEvent      : NIDAQmx Driver Errors
            %
            obj.CustomListener = addlistener(obj.AsyncIOChannel, ...
                'Custom', ...
                @obj.handleCustomEvent);
        end
        
        function delete(obj)
            try
                % Make sure the stream is closed
                obj.closeStream();
                
                % Unregister listeners
                delete(obj.DataWrittenListener);
                delete(obj.CustomListener);
                
                % Delete the AsyncIO Channel
                delete(obj.AsyncIOChannel);
                obj.AsyncIOChannel = [];
            catch e %#ok<NASGU>
            end
        end
    end
    
    %% AsyncIO Channel Methods
    methods
        function openStream(obj, taskHandle, numberOfScans, bufferingBlockSize, numChannels, isContinuous, externalTriggerTimeout)
            % Flush the input stream
            obj.flushStream();
            
            % Assign Input Channel Options
            obj.ChannelOptions.TaskHandle = uint64(taskHandle);
            obj.ChannelOptions.NumberOfScans = uint64(numberOfScans);
            obj.ChannelOptions.BufferingBlockSize = uint64(bufferingBlockSize);
            obj.ChannelOptions.NumberOfChannels = uint64(numChannels);
            obj.ChannelOptions.IsContinuous = logical(isContinuous);
            obj.ChannelOptions.ExternalTriggerTimeout = externalTriggerTimeout;
            
            % Start data acquisition
            obj.AsyncIOChannel.open(obj.ChannelOptions);
        end
        
        function flushStream(obj)
            obj.AsyncIOChannel.InputStream.flush();
        end
        
        function closeStream(obj)
            if ~isempty(obj.AsyncIOChannel)
                obj.AsyncIOChannel.close();
            end
        end
        
        function startTask(obj)
            % Start data acquisition
            obj.AsyncIOChannel.execute('StartTask', obj.ChannelOptions);
            if obj.Session.SyncManager.configurationRequiresExternalTriggerImpl()
                obj.AsyncIOChannel.execute('StartExternalTriggerTimeout', obj.ChannelOptions);
            end
        end
    end
    
    % DataWritten and CustomEvent handlers
    methods (Access = private)
        function handleDataAvailable(obj,~,eventData)
            % !!! Bug, this only handles results from a single task
            channels = obj.ChannelGroup.ChannelIOIndexMap;
            dataInCells = eventData.Source.readPackets(Inf);
            if isempty(dataInCells)
                obj.Session.handleDataAvailable([],zeros(0,obj.ChannelOptions.NumberOfChannels), ...
                    channels, double(obj.ChannelGroup.NumScansConfigured))
            end

            for iData = 1:numel(dataInCells)
                obj.Session.handleDataAvailable(dataInCells{iData}, channels, ...
                    double(obj.ChannelGroup.NumScansConfigured))
            end
        end
        
        function handleCustomEvent(obj,~,eventData)
            switch eventData.Type
                case 'DoneEvent'
                    error = [];
                case 'ExternalTriggerTimeoutErrorEvent'
                    obj.AsyncIOChannel.execute('StopExternalTriggerTimeout', obj.ChannelOptions);
                    error = MException('daq:Session:externalTriggerTimeout',...
                        getString(message('daq:Session:externalTriggerTimeout')));
                case 'ErrorEvent'
                    error = MException(eventData.Data);
                case 'NIDAQmxDriverEvent'
                    error = MException(eventData.Data.MessageID,eventData.Data.DriverMessage);
                otherwise
                    error = MException(eventData.Data);
            end
            
            % Stop the device
            obj.ChannelGroup.handleStop(error);
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end
end
