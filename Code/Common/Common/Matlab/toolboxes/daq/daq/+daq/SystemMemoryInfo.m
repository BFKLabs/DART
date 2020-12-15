classdef(Hidden) SystemMemoryInfo < daq.MemoryInfo
% SYSTEMMEMORYINFO Provide information about system memory.
%
%   SYSTEMMEMORYINFO class provides the information about the system
%   memory and the memory used by all the data acquisition objects present
%   in the workspace.
%
%   See also DAQMEM.
%
  
%    Copyright 2009 The MathWorks, Inc.
%    $Revision: 1.1.6.1 $  $Date: 2009/02/10 20:53:26 $
    
    properties 
        % Specifies a number between 0 and 100 that gives a general idea of
        % current memory utilization. 0 indicates no memory use and 100 
        % indicates full memory use.
        MemoryLoad;
        
        % Indicates the total number of bytes of physical memory.
        TotalPhys;
 
        % Indicates the number of bytes of physical memory available.
        AvailPhys;

        % Indicates the total number of bytes that can be stored in the
        % paging file. Note that this number does not represent the actual 
        % physical size of the paging file on disk.
        TotalPageFile;

        % Indicates the number of bytes available in the paging file.
        AvailPageFile;
        
        % Indicates the total number of bytes that can be described in the
        % user mode portion of the virtual address space of the calling 
        % process.
        TotalVirtual;
        
        % Indicates the number of bytes of unreserved and uncommitted
        % memory in the user mode portion of the virtual address space of 
        % the calling process.
        AvailVirtual;
        
        % The total memory used by all device objects.
        UsedDaq;
    end
    
    methods
        function obj = SystemMemoryInfo()
        % SYSTEMMEMORYINFO Constructs a system memory object.
        
        % Register all UDD classes. This is necessary in the event that
        % DAQMEM is the first DAT command executed.
        try
            daqmex;
            
            % Get memory information from the engine.
            memData = daq.engine.getmemoryinfo();
        catch ME
            ME = MException('daq:SystemMemoryInfo:daqmexLoadError', strrep('Error loading daqmex.', '\', '\\'));
            throwAsCaller(ME);
        end
            
            obj.MemoryLoad      = memData.MemoryLoad;
            obj.TotalPhys       = memData.TotalPhys;
            obj.AvailPhys       = memData.AvailPhys;
            obj.TotalPageFile   = memData.TotalPageFile;
            obj.AvailPageFile   = memData.AvailPageFile;
            obj.TotalVirtual    = memData.TotalVirtual;
            obj.AvailVirtual    = memData.AvailVirtual;
            obj.UsedDaq         = memData.UsedDaq;
        end
    end
    
    methods(Hidden)
        function disp(obj)
        % DISP function overloaded to display data in user friendly scaled
        % format.
        
            % Scale the values for display.
            MemoryLoadVal = obj.MemoryLoad;
            MemoryLoadUnits = '%';
            
            [TotalPhysVal TotalPhysUnits] = scaleBytes(obj, obj.TotalPhys);
            [AvailPhysVal AvailPhysUnits] = scaleBytes(obj, obj.AvailPhys);
            [TotalPageFileVal TotalPageFileUnits] = scaleBytes(obj, obj.TotalPageFile);
            [AvailPageFileVal AvailPageFileUnits] = scaleBytes(obj, obj.AvailPageFile);
            [TotalVirtualVal TotalVirtualUnits] = scaleBytes(obj, obj.TotalVirtual);
            [AvailVirtualVal AvailVirtualUnits] = scaleBytes(obj, obj.AvailVirtual);
            [UsedDaqVal UsedDaqUnits] = scaleBytes(obj, obj.UsedDaq);
            
            % Print the values in user friendly format.
            fprintf('%13s = %4d %s\n','MemoryLoad', MemoryLoadVal, MemoryLoadUnits);
            % NOTE: This format matches the format in DeviceMemoryInfo
            % for visual consistency.
            fprintf('%13s = %7.2f %2s \n', 'TotalPhys', TotalPhysVal, TotalPhysUnits,...
                'AvailPhys', AvailPhysVal, AvailPhysUnits, ...
                'TotalPageFile', TotalPageFileVal, TotalPageFileUnits,...
                'AvailPageFile', AvailPageFileVal, AvailPageFileUnits, ...
                'TotalVirtual', TotalVirtualVal, TotalVirtualUnits,...
                'AvailVirtual', AvailVirtualVal, AvailVirtualUnits,...
                'UsedDaq', UsedDaqVal, UsedDaqUnits);
        end
    end
    
end