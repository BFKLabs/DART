function out = daqhwinfo(obj, prop)
%DAQHWINFO Return information on the available hardware.
%
%    OUT = DAQHWINFO returns a structure, OUT, which contains data acquisition
%    hardware information.  This information includes the toolbox version,
%    MATLAB version and installed adaptors.
%
%    OUT = DAQHWINFO('ADAPTOR') returns a structure, OUT, which contains 
%    information related to the specified adaptor, ADAPTOR.
%
%    OUT = DAQHWINFO('ADAPTOR','Property') returns the adaptor information for
%    the specified property, Property. Property must be a single string. OUT is
%    a cell array.
%
%    OUT = DAQHWINFO(OBJ) where OBJ is any data acquisition device object, 
%    returns a structure, OUT, containing hardware information such as adaptor, 
%    board information and subsystem type along with details on the hardware
%    configuration limits and number of channels/lines.  If OBJ is an array 
%    of device objects then OUT is a 1-by-N cell array of structures where 
%    N is the length of OBJ.   
%
%    OUT = DAQHWINFO(OBJ, 'Property') returns the hardware information for the 
%    specified property, Property.  Property can be a single string or a cell
%    array of strings.  OUT is a M-by-N cell array where M is the length of OBJ 
%    and N is the length of 'Property'.
%
%    Example:
%      out = daqhwinfo
%      out = daqhwinfo('winsound')
%      ai  = analoginput('winsound');
%      out = daqhwinfo(ai)
%      out = daqhwinfo(ai, 'SingleEndedIDs')
%      out = daqhwinfo(ai, {'SingleEndedIDs', 'TotalChannels'})
%
%    See also DAQHELP.
%

%    MP 4-16-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.7.2.8 $  $Date: 2008/06/16 16:35:40 $

ArgChkMsg = nargchk(0,2,nargin);
if ~isempty(ArgChkMsg)
    error('daq:daqhwinfo:argcheck', ArgChkMsg);
end

if nargout > 1
   error('daq:daqhwinfo:argcheck', 'Too many output arguments.')
end

% Error if an invalid handle was passed.
if ~all(isvalid(obj))
   error('daq:daqhwinfo:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Initialize variables.
outputStr = 0;
uddobjs = daqgetfield(obj, 'uddobject');

% Return either all the properties or just the specified property.
switch nargin 
case 1   % Obtain the hw info.
   try
      % Loop through the array.
      for i = 1:length(uddobjs)
         currentObj = get(obj,i);
         if isa(currentObj, 'digitalio')
            out{i} = gethwinfo(uddobjs(i)); %#ok<AGROW>
            try
                out{i}.Port = localCreatePortStructure(currentObj); %#ok<AGROW>
            catch e
                localHandleError(e)
            end
         else
            out{i} = daqhwinfo(currentObj); %#ok<AGROW>
         end
      end
      
      % Return a non-cell if obj is 1-by-1.
      if length(uddobjs) == 1
         out = out{:};
      end
   catch e
      error('daq:daqhwinfo:unexpected', e.message);
   end
case 2   % Find the properties specified.
   % If the property specified is a string make it a cell.
   if ischar(prop)
      outputStr = 1;
      prop = {prop};
   end
   
   % Error on wrong data type.
   if ~iscellstr(prop)
      error('daq:daqhwinfo:invalidproperty', 'Property must either be a string or a cell array of strings.');
   end
   
   % Initialize output.
   out = cell(length(uddobjs), length(prop));
   
   % Get the property values.
   for i = 1:length(uddobjs)
      for j = 1:length(prop)
         try
            % If the Port property is specified, need to construct
            % the portStructure.
            if ~strncmpi(prop{j}, 'port', length(prop{j}))
               out{i,j} = gethwinfo(uddobjs(i),prop{j});
            else
               out{i,j} = localCreatePortStructure(obj);
            end
         catch e
            error('daq:daqhwinfo:unexpected', e.message);
         end
      end
   end
      
   % If the property was given as a string and obj is 1-by-1, output
   % a string.
   if outputStr && length(uddobjs) == 1
      out = out{:};
   end
end

% **********************************************************************
% Create the Port Structure.
function [portStruct] = localCreatePortStructure(obj)

% Initialize variables.
uddobj = daqgetfield(obj, 'uddobject');

portIDs = gethwinfo(uddobj, 'PortIDs');
portMasks = gethwinfo(uddobj, 'PortLineMasks');
portDir = gethwinfo(uddobj, 'PortDirections');
config = gethwinfo(uddobj, 'PortLineConfig');

% Create the portStruct.
for i = 1:length(portIDs)
  portStruct(i).ID = portIDs(i); %#ok<AGROW>
  portStruct(i).LineIDs = []; %#ok<AGROW>
  portStruct(i).Direction = ''; %#ok<AGROW>
  portStruct(i).Config = ''; %#ok<AGROW>

  % Determine which lines are supported.

  % masks = 0 - Line is not supported.
  % masks = 1 - Line is supported.
  % Ex. masks = 43 = [1 1 0 1 0 1 0 0]
  % Supported lines = [0 1 3 5].
  if portMasks(i) < 0
      % The mask comes across COM to us as a long (32 bits) and if the first line
      % is supported (for instance 0xffffffff) the long is considered
      % negative. dec2binvec cannot deal with negative numbers, so special
      % handling ensures we never send a negative number to dec2binvec by casting the
      % int32 to a uint32. G305100.
      portMasks(i)= double(typecast(int32(portMasks(i)),'uint32'));
  end
  masks = dec2binvec(portMasks(i));
  zeroIndex = find(masks == 0);

  % Convert the 0's and 1's to the line numbers.
  lineMasks = (0:length(masks)-1) .* masks;

  % Remove the lines that are not supported.
  lineMasks(zeroIndex) = []; %#ok<FNDSB>

  % Add lineIDs to the portStruct.
  portStruct(i).LineIDs = lineMasks; %#ok<AGROW>

  % Determine the port direction.
  switch (portDir(i))
  case 0
     portStruct(i).Direction = 'in'; %#ok<AGROW>
  case 1
     portStruct(i).Direction = 'out'; %#ok<AGROW>
  case 2
     portStruct(i).Direction = 'in/out'; %#ok<AGROW>
  end

  % Determine if line configurable or port configurable.
  switch (config(i))
  case 0
     portStruct(i).Config = 'port'; %#ok<AGROW>
  case 1
     portStruct(i).Config = 'line'; %#ok<AGROW>
  end
end
   
% **********************************************************************
% Remove any extra carriage returns.
function localHandleError(e)

% Initialize variables.
errmsg = e.message;

% Remove the trailing carriage returns from errmsg.
while errmsg(end) == sprintf('\n')
   errmsg = errmsg(1:end-1);
end

throwAsCaller(MException('daq:daqhwinfo:unexpected',errmsg));