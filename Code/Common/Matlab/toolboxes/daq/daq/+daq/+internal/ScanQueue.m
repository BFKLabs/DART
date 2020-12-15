classdef (Hidden, Sealed) ScanQueue < handle
    %ScanQueue Multipurpose high performance circular buffer
    %    The ScanQueue is used to store data in a FIFO buffer utilizing a
    %    circular buffer.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
        function obj = ScanQueue(channelsPerScan, initialCapacity, requireTimeStamps)
            error(nargchk(1,3,nargin,'struct'))
            if nargin < 2
                initialCapacity = 1000;
            end
            if nargin < 3
                requireTimeStamps = true;
            end
            
            %Initialize queue parameters
            obj.reset();
            obj.ChannelsPerScan = channelsPerScan;
            obj.RequireTimeStamps = requireTimeStamps;
            obj.adjustCapacity(initialCapacity)
        end
    end
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
    end
    
    % Read only properties
    properties (SetAccess = private)
        ChannelsPerScan
        NumberOfScans
        Capacity
    end
    
    %% Methods
    methods

        function reset(obj)
            obj.Data = [];
            obj.TimeStamps = [];
            obj.NextIndexToWrite = 1;
            obj.NextIndexToRead = [];
         end

        function writeScansToQueue(obj,newData,newTimeStamps)
            if size(newData,2) ~= obj.ChannelsPerScan
                error(message('daq:general:invalidScanData'));
            end
            scansRemaining = size(newData,1);
            
            % It's legal to queue no data -- don't do anything
            if scansRemaining == 0
                return
            end
            
            % G876533: For certain high sample rates and low duration
            % acquisitions, doubling once may not be enough
            while (scansRemaining + obj.NumberOfScans > obj.Capacity)
                % If there isn't enough room, double the size of the buffer
                adjustCapacity(obj,obj.Capacity * 2);
            end

            if isempty(obj.NextIndexToRead)
                obj.NextIndexToRead = obj.NextIndexToWrite;
            end
            lastIndex = min(obj.NextIndexToWrite + scansRemaining - 1,obj.Capacity);
            scansToCopy = lastIndex - obj.NextIndexToWrite + 1;
            % write everything from NextIndexToWrite to capacity first
            obj.Data(obj.NextIndexToWrite:lastIndex,:) = newData(1:scansToCopy,:);
            if obj.RequireTimeStamps
                obj.TimeStamps(obj.NextIndexToWrite:lastIndex) = newTimeStamps(1:scansToCopy);
            end
            % Next index to write is at lastIndex plus 1
            obj.NextIndexToWrite = lastIndex + 1;
            if obj.NextIndexToWrite == obj.Capacity + 1
                % Handle rollover
                obj.NextIndexToWrite = 1;
            end
            scansRemaining = scansRemaining - scansToCopy;
            if scansRemaining ~= 0
                % Write starting from the first element up
                obj.Data(1:scansRemaining,:) = newData(scansToCopy+1:end,:);
                if obj.RequireTimeStamps
                    obj.TimeStamps(1:scansRemaining) = newTimeStamps(scansToCopy+1:end);
                end
                obj.NextIndexToWrite = scansRemaining + 1;
            end
        end
        
        function [data,timeStamps] = readScansFromQueue(obj,scansRequested)
            if nargin < 2 || isinf(scansRequested) || scansRequested > obj.NumberOfScans
                scansRequested = obj.NumberOfScans;
            end
            [data,timeStamps] = internalReadScansFromQueue(obj,scansRequested,scansRequested);
        end
        
        function sizeInfo = size(obj)
            sizeInfo = [obj.NumberOfScans obj.ChannelsPerScan];
        end
    end
    
    %% Property accessor methods
    methods
        function result = get.NumberOfScans(obj)
            if isempty(obj.NextIndexToRead)
                result = 0;
            elseif obj.NextIndexToWrite == obj.NextIndexToRead
                result = obj.Capacity;
            elseif obj.NextIndexToWrite < obj.NextIndexToRead
                result = obj.Capacity - obj.NextIndexToRead + obj.NextIndexToWrite;
            else
                result = obj.NextIndexToWrite - obj.NextIndexToRead;
            end
        end
    end
    
    %% Private properties
    properties (GetAccess = private,SetAccess = private)
        Data
        TimeStamps
        
        NextIndexToWrite
        NextIndexToRead
        
        RequireTimeStamps
    end

    %% Private methods
    methods (Access = private)
        function adjustCapacity(obj,newCapacity)
            if ~isempty(obj.Capacity) && newCapacity <= obj.Capacity
                % DataQueue capacity can only increase
                return
            end
            
            scansCopied = obj.NumberOfScans;
            if obj.NumberOfScans == 0
                % Initialize a new buffer
            	newData = zeros(newCapacity,obj.ChannelsPerScan);
                if obj.RequireTimeStamps
                    newTimeStamps = zeros(newCapacity,1);
                else
                    newTimeStamps = [];
                end
                obj.NextIndexToRead = [];
            else
                % Read the old buffer out into a new one with a larger capacity
                [newData,newTimeStamps] = internalReadScansFromQueue(obj,obj.NumberOfScans,newCapacity);
                obj.NextIndexToRead = 1;
            end
            
            % Switch to newData
            obj.NextIndexToWrite = scansCopied + 1;
            obj.Data = newData;
            obj.TimeStamps = newTimeStamps;
            obj.Capacity = newCapacity;
        end
           
        function [data,timeStamps] = internalReadScansFromQueue(obj,scansRequested,newCapacity)
            scansCopied = 0;
            scansRemaining = scansRequested;
            data = zeros(newCapacity,obj.ChannelsPerScan);
            if obj.RequireTimeStamps
                timeStamps = zeros(newCapacity,1);
            else
                timeStamps = [];
            end
            if obj.NextIndexToWrite <= obj.NextIndexToRead
                % Read everything from NextIndexToRead to capacity first
                lastIndex = min(obj.NextIndexToRead + scansRemaining - 1,obj.Capacity);
                scansCopied = lastIndex - obj.NextIndexToRead + 1;
                data(1:scansCopied,:) = obj.Data(obj.NextIndexToRead:lastIndex,:);
                if obj.RequireTimeStamps
                    timeStamps(1:scansCopied) = obj.TimeStamps(obj.NextIndexToRead:lastIndex);
                end
                obj.NextIndexToRead = mod(lastIndex,obj.Capacity) + 1;
                scansRemaining = scansRequested - scansCopied;
            end
            if scansRemaining ~= 0
                % Read starting from the first element up
                data(scansCopied + 1:scansCopied + scansRemaining,:) =...
                    obj.Data(obj.NextIndexToRead:obj.NextIndexToRead + scansRemaining - 1,:);
                if obj.RequireTimeStamps
                    timeStamps(scansCopied + 1:scansCopied + scansRemaining) =...
                        obj.TimeStamps(obj.NextIndexToRead:obj.NextIndexToRead + scansRemaining - 1);
                    obj.NextIndexToRead = obj.NextIndexToRead + scansRemaining;
                end
            end
            if obj.NextIndexToRead == obj.NextIndexToWrite
                obj.NextIndexToRead = [];
            end
        end
    end
end
