classdef (Hidden) AsyncIOOutputChannel < daq.internal.BaseClass
    %AsyncIOOutputChannel AsyncIO Output Channel
    
    % Copyright 2012 The MathWorks, Inc.
    
    %% private properties
    properties(Access = private)
        PluginDir;
        ConverterPluginPath;
        DevicePluginPath;
        AsyncIOChannel;
        StreamLimits;
        CustomListener;
        ChannelOptions;
        
        Session;
        ChannelGroup;
        
        ScanCount;
        LastBlock;
    end
    
    %% constructor/destructor
    methods
        function obj = AsyncIOOutputChannel(session, channelGroup, pluginName)
            % Initialize properties
            obj.Session = session;
            obj.ChannelGroup = channelGroup;
            
            obj.DevicePluginPath = '';
            obj.AsyncIOChannel = [];
            obj.StreamLimits = [Inf Inf];
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
            
            obj.ScanCount = 0;
            obj.LastBlock = [];
            
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
            % Assign Output Channel Options
            obj.ChannelOptions.TaskHandle = uint64(taskHandle);
            obj.ChannelOptions.NumberOfScans = uint64(numberOfScans);
            obj.ChannelOptions.BufferingBlockSize = uint64(bufferingBlockSize);
            obj.ChannelOptions.NumberOfChannels = uint64(numChannels);
            obj.ChannelOptions.IsContinuous = logical(isContinuous);
            obj.ChannelOptions.ExternalTriggerTimeout = externalTriggerTimeout;
            
            % Prime Output Buffer (assumes data was written to the output stream)
            obj.AsyncIOChannel.execute('PrimeOutputBuffer', obj.ChannelOptions);
            
            % Start data generation
            obj.AsyncIOChannel.open(obj.ChannelOptions);
        end
        
        function flushStream(obj)
            obj.AsyncIOChannel.OutputStream.flush();
            
            % G645636: LastBlock must be flushed between session runs
            obj.LastBlock = [];
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
    
    %% Write Data
    methods
        function doWriteData(objArray,dataToOutput)
            for iObj = 1:numel(objArray)
                obj = objArray(iObj);
                firstRowToCopy = 1;
                totalNumRows = size(dataToOutput,1);
                blockSize = double(obj.ChannelGroup.BufferingBlockSize);
                lastBlockRows = size(obj.LastBlock, 1);
                
                % If we have a partial block from a previous call to queue data
                % then process that block first
                if lastBlockRows > 0
                    if lastBlockRows + totalNumRows < blockSize
                        % If we don't have enough data for a full block, then
                        % just update the partial block with the new data and be
                        % done.
                        lastRowToCopy = totalNumRows;
                        obj.LastBlock(lastBlockRows+1:lastBlockRows+totalNumRows, :) = ...
                            dataToOutput(firstRowToCopy:lastRowToCopy,:);
                        return;
                    else
                        % If we have enough data to complete the last partial block,
                        % write it to the channel
                        lastRowToCopy = blockSize - lastBlockRows;
                        obj.LastBlock(lastBlockRows+1:lastBlockRows+lastRowToCopy, :) = ...
                            dataToOutput(firstRowToCopy:lastRowToCopy,:);
                        obj.AsyncIOChannel.OutputStream.write(obj.LastBlock);
                        obj.ScanCount = obj.ScanCount + blockSize;
                        obj.LastBlock = [];
                        firstRowToCopy = lastRowToCopy + 1;
                    end
                end
                
                % Break up the data into blocks that are evenly divisible
                % by the BufferingBlockSize
                while (totalNumRows - firstRowToCopy + 1) >= blockSize
                    lastRowToCopy = firstRowToCopy + blockSize - 1;
                    obj.AsyncIOChannel.OutputStream.write(dataToOutput(firstRowToCopy:lastRowToCopy,:));
                    obj.ScanCount = obj.ScanCount + blockSize;
                    firstRowToCopy = lastRowToCopy + 1;
                end
                
                % Save partial block data to be processed when more data is
                % available for a complete block size
                if (firstRowToCopy <= totalNumRows)
                    obj.LastBlock = dataToOutput(firstRowToCopy:totalNumRows, :);
                end
            end
        end
        
        function doWriteDataLastBlock(objArray)
            for iObj = 1:numel(objArray)
                obj = objArray(iObj);
                blockSize = double(obj.ChannelGroup.BufferingBlockSize);
                lastBlockRows = size(obj.LastBlock, 1);
                
                if ~obj.Session.IsContinuous && lastBlockRows > 0
                    % When the user calls start, write the last block of data
                    % padded by repeating the last row of output data that was
                    % queued earlier
                    obj.LastBlock(lastBlockRows+1:blockSize,:) = ...
                        repmat(obj.LastBlock(end,:),blockSize-lastBlockRows,1);
                    obj.AsyncIOChannel.OutputStream.write(obj.LastBlock);
                    obj.ScanCount = obj.ScanCount + blockSize;
                    obj.LastBlock = [];
                end
            end
        end
    end
    
    %% CustomEvent handler
    methods (Access = private)
        function handleCustomEvent(obj,~,eventData)
            switch eventData.Type
                case 'ScansGeneratedEvent'
                    obj.Session.handleOutputEvent(eventData.Data.ScansGenerated);
                    return
                case 'DoneEvent'
                    error = [];
                case 'ExternalTriggerTimeoutErrorEvent'
                    obj.AsyncIOChannel.execute('StopExternalTriggerTimeout', obj.ChannelOptions);
                    error = MException('daq:Session:externalTriggerTimeout',...
                        getString(message('daq:Session:externalTriggerTimeout')));
                case 'ErrorEvent'                    
                    error = MException(eventData.Data);
                case 'NIDAQmxDriverEvent'
                    switch (eventData.Data.MessageID)
                        % Warning 200010: StoppedBeforeDone
                        case 'nidaq:ni:NIDAQmxWarning200010'
                            error = [];
                            % Sometimes, an underflow error is caught by
                            % by the driver due a race condition in the
                            % DevicePlugin
                        case 'nidaq:ni:NIDAQmxError200621'
                            id = 'nidaq:ni:DataMissedAO';
                            error = MException(id, getString(message(id, num2str(obj.Session.ScansOutputByHardware ) )));
                        otherwise
                            error = obj.Session.processNIDAQmxDriverError(obj.ChannelGroup.ChannelIOIndexMap, ...
                                eventData.Data.MessageID, ...
                                eventData.Data.DriverMessage);
                    end
                case 'DataMissedEvent'
                    % Underflow error: custom event fired by DevicePlugin
                    % This error may also be caught as a NIDAQmx Driver
                    % Event
                    id = eventData.Data.MessageID;
                    error = MException(id,getString(message(id, num2str(eventData.Data.LastValidScan) ) ));
                otherwise
                    error = MException('nidaq:ni:unexpectedEvent',eventData.Type);
            end
            % Reset the number of scans queued back to zero
            obj.ScanCount = 0;
            
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
