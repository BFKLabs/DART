function out = daqmem(varargin)
%DAQMEM Allocate or display memory for one or more device objects.
%
%    OUT = DAQMEM returns an object containing the properties: MemoryLoad,
%    TotalPhys, AvailPhys, TotalPageFile, AvailPageFile, TotalVirtual, 
%    AvailVirtual and UsedDaq. All the properties except UsedDaq are 
%    identical to the fields returned by Windows' MemoryStatus function.
%    UsedDaq returns the total memory used by all data acquisition device 
%    objects.
%
%    OUT = DAQMEM(OBJ) returns an 1-by-N array of objects where N is the 
%    length of OBJ. It contains three properties: DeviceObjectName, 
%    UsedBytes and MaxBytes for the specified device object. The 
%    DeviceObjectName property displays the name of the specified device 
%    object. The UsedBytes property returns the amount of memory in bytes 
%    used by the specified device object. The MaxBytes property returns the
%    maximum memory in bytes that can be used by the specified device 
%    objects.
%
%    DAQMEM(OBJ, VALUE) sets the maximum memory that can be allocated
%    for the specified device object, OBJ, to VALUE.  OBJ can be either
%    a single device object or an array of device objects.  If an array
%    of device objects is specified, VALUE can be either a single value
%    applied to all device objects specified in OBJ or VALUE
%    can be a vector of values (the same length as OBJ) where each
%    vector element corresponds to a different device object in OBJ.
%
%    Example:
%      ai1 = analoginput('winsound');
%      ai2 = analoginput('nidaq', 'Dev1');
%      out = daqmem;
%      out = daqmem(ai1);
%      daqmem([ai1 ai2], 320000);
%      daqmem([ai1 ai2], [640000 480000]);
%
%    See also DAQHELP.
%

%    MP 11-17-98
%    Copyright 1998-2010 The MathWorks, Inc.
%    $Revision: 1.7.2.12 $  $Date: 2010/11/08 02:16:31 $

daq.internal.errorIfLegacyInterfaceUnavailable

% Parse the input.
switch nargin
case 0
    % Returns an object of class daq.SystemMemoryInfo with system memory
    % information and total memory used by data acquisition objects.
    
    out = daq.SystemMemoryInfo();
    
otherwise
    error('daq:daqmem:argcheck', 'Invalid input argument.  Type ''daqhelp daqmem'' for additional information.');
end


