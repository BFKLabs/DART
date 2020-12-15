function out = daqmem(obj, value)
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
%    Copyright 1998-2009 The MathWorks, Inc.
%    $Revision: 1.7.2.9 $  $Date: 2009/02/10 20:53:28 $

% The first input must be a daqdevice object otherwise error.
if ~isempty(obj) && ~isa(obj, 'daqdevice')
   error('daq:daqmem:argcheck', 'Invalid input argument.  Type ''daqhelp daqmem'' for additional information.');
end

% Determine if an invalid handle was passed.
if ~all(isvalid(obj))
   error('daq:daqmem:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

switch nargin
case 1
   % Ex. daqmem([ai1 ai2]);
   
   uddobjects = daqgetfield(obj, 'uddobject');
  
   % Returns an object of class daq.DeviceMemoryInfo with device memory
   % information.
   out = daq.DeviceMemoryInfo(uddobjects);
case 2
   % Ex. daqmem([ai1 ai2], 64000); 
   % Ex. daqmem([ai1 ai2], [64000 32000]);
      
   % VALUE must be a double.
   if isempty(value) || ~isa(value, 'double')
      error('daq:daqmem:argcheck', 'Invalid input argument.  VALUE must be a double.');
   end
   
   % The length of VALUE must be either 1 or the length of OBJ.
   if length(value) ~= 1 && length(value) ~= length(obj)
      error('daq:daqmem:invalidvalue', 'VALUE must have the same length as OBJ or have a length of one.');
   end
   
   % Loop through each object and set the maximum memory that
   % can be allocated for the object.
   uddobjects = daqgetfield(obj, 'uddobject');
   index = 1;
   for i = 1:length(uddobjects)
      try
         set(uddobjects(i), 'MemoryMax', value(index));
      catch e
         error('daq:daqmem:unexpected', e.message)
      end
      
      % Increment the index if VALUE is the same length as OBJ.
      if length(value) > 1
         index = index+1;
      end
   end
end