classdef(Hidden) DeviceMemoryInfo < daq.MemoryInfo
% DEVICEMEMORYINFO Provide information about DAT object memory.
% 
%   DEVICEMEMORYINFO class provides information about memory occupied by
%   each object passed to the DAQMEM.
%
%   See also DAQMEM.
%

%    Copyright 2009 The MathWorks, Inc.
%    $Revision: 1.1.6.1 $  $Date: 2009/02/10 20:53:24 $

    properties 
        DeviceObjectName;
        UsedBytes;
        MaxBytes;
    end
    
    methods
        function obj = DeviceMemoryInfo(uddObjectArray)
        % DEVICEMEMORYINFO Constructs a device memory object array.    
        %
        % uddObjectArray is an array of udd device objects returned by
        % the engine.
            obj = daq.DeviceMemoryInfo.newarray(1,length(uddObjectArray));
            for deviceIndex = 1:length(uddObjectArray)
                % Get the name, memory used and memory max values.
                try
                    obj(deviceIndex).DeviceObjectName = uddObjectArray(deviceIndex).Name;
                    obj(deviceIndex).UsedBytes = getmemoryused(uddObjectArray(deviceIndex));
                    obj(deviceIndex).MaxBytes = get(uddObjectArray(deviceIndex),'MemoryMax');
                    
                catch ME
                    ME = MException('daq:DeviceMemoryInfo:deviceObjectError', ME.message);
                    throwAsCaller(ME);
                end
            end
        end
    end 
    
    methods (Hidden)
        function disp(obj)
        % DISP function overloaded to display data in user friendly scaled 
        % format.
            
            % Scale the values for display.
            for objectIndex = 1:length(obj)
                [UsedBytesVal UsedBytesUnits] = scaleBytes(obj(objectIndex), obj(objectIndex).UsedBytes);
                [MaxBytesVal MaxBytesUnits] = scaleBytes(obj(objectIndex), obj(objectIndex).MaxBytes);
                
                % Print the values in user friendly format.
                fprintf('%s\n', obj(objectIndex).DeviceObjectName)
                % NOTE: This format matches the format in SystemMemoryInfo
                % for visual consistency.
                fprintf('%13s = %7.2f %2s \n', 'UsedBytes', UsedBytesVal, UsedBytesUnits,...
                    'MaxBytes',     MaxBytesVal,     MaxBytesUnits)
            end
        end
    end 
    
end