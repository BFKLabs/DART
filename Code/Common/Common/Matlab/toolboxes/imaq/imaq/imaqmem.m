function out = imaqmem(varargin)
%IMAQMEM Limit or display memory in use by the Image Acquisition Toolbox.
%
%    MEM = IMAQMEM returns a structure, MEM, containing the following
%    fields:
%       MemoryLoad       - a number between 0 and 100 that gives a general
%                          idea of current memory utilization.
%       TotalPhys        - total number of bytes of physical memory. 
%       AvailPhys        - number of bytes of physical memory available. 
%       TotalPageFile    - total number of bytes that can be stored in the
%                          paging file.
%       AvailPageFile    - number of bytes available in the paging file. 
%       FrameMemoryLimit - memory limit for image acquisition frame memory
%                          in bytes.
%       FrameMemoryUsed  - frame memory in bytes currently allocated by the
%                          image acquisition toolbox.
%
%    In addition on Windows platforms, the following two fields are also
%    available:
%       TotalVirtual     - total number of bytes that can be described in
%                          the user mode portion of the virtual address
%                          space.
%       AvailVirtual     - number of bytes of unreserved and uncommitted
%                          memory in the user mode portion of the virtual
%                          address space.
%
%    IMAQMEM('FIELD') returns memory information for the specified memory
%    field, FIELD.
%
%    IMAQMEM(LIMIT) configures the frame memory limit, in bytes, for the
%    Image Acquisition Toolbox. LIMIT is used to determine the maximum amount
%    of memory the toolbox can use for logging image frames.
%
%    Configuring this limit does not remove any logged frames from the 
%    image acquisition engine. Use FLUSHDATA to remove any frames that have
%    been logged by a video input object, or use GETDATA to return logged 
%    frames to the MATLAB workspace.
%
%    See also IMAQDEVICE/FLUSHDATA, IMAQDEVICE/GETDATA, VIDEOINPUT. 

%    RDD 09-11-02
%    Copyright 2001-2010 The MathWorks, Inc.

% Check the number of inputs.
error(nargchk(0, 1, nargin, 'struct'));

try
    if (nargin == 0)
        % No inputs specified
        % Ex. IMAQMEM
        out = imaqmex('memorystatus');
    else 
        % Number of inputs is 1.
        if isnumeric(varargin{1})
            % Input is a LIMIT.
            % Ex. IMAQMEM(LIMIT)
            
            if (numel(varargin{1}) > 1)
                % Check that LIMIT is a numeric scalar.
                error(message('imaq:imaqmem:nonScalarLIMIT'));
               
            elseif (varargin{1} <= 0)
                % Check that LIMIT contains a positive value.
                error(message('imaq:imaqmem:nonPositiveLIMIT'));
            end
            
            % Make sure LIMIT is a double.
            if ~isa(varargin{1}, 'double')
                varargin{1} = double(varargin{1});
            end
            
        elseif (ischar(varargin{1}))
            % Input is a FIELD.
            % Ex. IMAQMEM('FIELD')
            
            % Check that FIELD is a scalar string.
            if (size(varargin{1},1) ~= 1)
               error(message('imaq:imaqmem:nonScalarFIELD'));
            end%if
 
            % Valid IMAQ memory field names.
            validFields = {'MemoryLoad', 'TotalPhys', 'AvailPhys', ...
                'TotalPageFile', 'AvailPageFile', 'FrameMemoryLimit', ...
                'FrameMemoryUsed'};
            
            if ispc
                validFields = [validFields, {'TotalVirtual', 'AvailVirtual'}];
            end
            
            % Find the FIELD positional value. 
            position = strmatch(lower(varargin{1}), lower(validFields));
            
            if (length(position) == 1)
                % Select the first matching case if multiple cases exist.
                varargin{1} = validFields{position};
            else
                % User entered an invalid FIELD.
                error(message('imaq:imaqmem:invalidFIELD'));
            end%if-else
        else
            % Input is neither a LIMIT nor a FIELD.
            error(message('imaq:imaqmem:invalidInputType'));
        end%if-else
       
        % Return the structure or field value if requested.
        out  = imaqmex('memorystatus',varargin{1});
        
        % If the input is a LIMIT and its value is smaller than the amount
        % of memory currently used, send a warning.
        if isnumeric(varargin{1})
            % Input is a number, so out is guaranteed to be a structure.
            if (out.FrameMemoryUsed > varargin{1})
                warning(message('imaq:imaqmem:exceededLIMIT'));
            end%if
        end%if
    end
catch exception
    throw(exception);
end


