function chan = addchannel(obj,hwid,varargin)
%ADDCHANNEL Add channels to analog input or analog output object.
%
%    CHANS = ADDCHANNEL(OBJ, HWCH) adds an array of channels, the length of
%    vector HWCH, to analog input or analog output object OBJ.  The channels
%    are assigned to the hardware channels specified in vector HWCH.  The 
%    channel array is returned to CHANS.  OBJ must be 1-by-1.
%
%    CHANS = ADDCHANNEL(OBJ, HWCH, NAMES) appends an array of channels, the 
%    length of vector HWCH, to analog input or analog output object OBJ.
%    The channels are assigned to the hardware channels specified in vector
%    HWCH.  All channels are created with the names specified in NAMES.
%    If a single channel is added, NAMES can be either a cell string array
%    or a string.  If multiple channels are added, NAMES can be either a
%    single name in which case all channels added will have the same name 
%    or NAMES can be a cell string array with the same length as HWCH.
%
%    CHANS = ADDCHANNEL(OBJ, HWCH, INDEX)
%    CHANS = ADDCHANNEL(OBJ, HWCH, INDEX, NAMES) inserts an array of channels   
%    into OBJ indexed by vector INDEX. The length of vector HWCH must be equal  
%    to the length of INDEX, otherwise an error is generated and no channels  
%    are inserted.  INDEX must be an increasing vector.
%
%    The channel group is resized accordingly after any channel insertions. 
%    Channels that are added without specifying INDEX are added to OBJ with
%    an increasing index position.  
%
%    If channels are not named, they can only be referenced using the index 
%    notation.  If they are named, the named reference notation is permitted 
%    in addition to the index notation.  Named indexing cannot be used for
%    channels with names which contain symbols.
%
%    The resulting channel group cannot contain any gaps or indices without 
%    channels assigned.  This will cause an error.
%
%    Example:
%       AI = analoginput('winsound');
%       chan = addchannel(AI, [1 2]);
% 
%    This adds 2 channels to the analog input object AI. 
% 
%    See also PROPINFO, DAQHELP, DAQDEVICE/DELETE, DAQRESET, MAKENAMES.
%

%    MP 4-20-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.13.2.10 $  $Date: 2011/10/31 06:06:56 $

% Error if the HWCH were not passed.
if nargin==1,
   error('daq:addchannel:argcheck', 'Not enough input arguments.  HWCH must be defined with hardware IDs.');
end

% Error if not enough input arguments were passed.
ArgChkMsg = nargchk(2,4,nargin);
if ~isempty(ArgChkMsg)
    error('daq:addchannel:argcheck', ArgChkMsg);
end

% Error if the object is not a device array or an analoginput or analogoutput object.
if ((length(obj) > 1) || ~(isa(obj,'analoginput') || isa(obj, 'analogoutput')))
   error('daq:addchannel:invalidobject', 'OBJ must be a 1-by-1 analog input or analog output object.');
end

% Error if an invalid object was passed.
if ~all(isvalid(obj))
   error('daq:addchannel:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Error if an invalid HWCH was passed.
if ~strcmp(class(hwid), 'double') || isempty(hwid)
   error('daq:addchannel:argcheck', 'Invalid second input argument, HWCH.  HWCH must be a double.');
end

% Determine the underlying UDD object
uddobj = daqgetfield(obj,'uddobject');

% Get the name of the channel property
s = struct(obj);
channelprop = s.info.child;

% Get the name of the channel name property
channelnameprop = strcat( channelprop, 'Name' );

% Initialize variables.
name = [];
index = [];
old_index=[];
% Indicates whether the NAME is specified.
nameflag = 1;  
% Indicates whether the INDEX is specified.
indexflag = 1;  

% Parse the input.
switch nargin
case 2
   % addchannel(obj, hwid);
   nameflag = 0;
   indexflag = 0;
case 3
   % addchannel(obj, hwid, index); index can be a vector of indices.
   % addchannel(obj, hwid, name);  name can be a cell array of names.
   if isnumeric(varargin{1})
      % Get the old indices and parse input into index.
      uddchild = get( uddobj, channelprop);
      if ~isempty(uddchild)
         old_index = get(uddchild, 'Index');
      end
      nameflag = 0;
      index = varargin{1};
   else
      % Parse the input into name.  
      indexflag = 0;
      name = varargin{1};
   end
case 4
   % addchannel(obj, hwid, index, name);
   % Get the old indices.
   uddchild = get(uddobj, channelprop);
   if ~isempty(uddchild)
      old_index = get(uddchild, 'Index');
   end
   % Parse the input into index and name.
   index = varargin{1};
   name = varargin{2};
end

% Error if the index is not numeric.
if ~strcmp(class(index), 'double') || (indexflag == 1 && isempty(index))
   error('daq:addchannel:invalidindex', 'An invalid INDEX value was specified.  INDEX must be a double.');
end

% Error if the name is not a string or a cell array of strings.
if nameflag
   if ~(ischar(name) || iscellstr(name)) || (iscell(name) && isempty(name))
      error('daq:addchannel:invalidname', 'An invalid NAMES value was specified.  Name must be a string or cell array of strings.');
   end
end

% Length of hwid must equal the length of the index otherwise no channel
% objects are created.
if ~isempty(index)
   if (length(hwid) ~= length(index))
      error('daq:addchannel:inconsistentindex', 'The length of HWCH must equal the length of INDEX.')
   end
end

% Error if NAMES is not an array of strings.
if iscell(name) && length(name)~=numel(name),
   error('daq:addchannel:invalidname', 'NAMES must be a 1-D array of cell strings.')
end

% If a single name is given convert it to a cell.
if ischar(name)
   name = {name};
end

% Error if the number of names provided does not equal the number of
% hardware ids specified (if more than one name is supplied).
if length(name) > 1 && length(name) ~= length(hwid)
   error('daq:addchannel:invalidname', 'Invalid number of NAMES provided for the number of hardware IDs specified in HWCH.')
end

% Create the channel objects.  Concatenate channels as they're created.
chan={};
chanindex = [];

% When adding channels the device may automatically reduce the sample rate
% for each channel added. Suppress the warning during the loop. 
% If needed one warning will be output at the end.
warningState = warning('off', 'daq:daqmex:propertyConfigurationError');
% Cache the sample rate before the channels are added.
sampleRateBefore = uddobj.SampleRate;

for i = 1:length(hwid)
   try
      % Create the channel cell array.
      uddchani = addchannel( uddobj, hwid(i));
      chani = daqgate('privateUDDToMATLAB', uddchani);
      chan = [chan; {chani}]; %#ok<AGROW>
      
      % Store what indices have been added
      chanindex = [chanindex get(uddchani, 'Index')]; %#ok<AGROW>
      
      % Assign the name to the channel if one was supplied.
      if ~isempty(name) 
         set(uddchani, channelnameprop, name{1});
         if length(name) > 1
            name(1) = [];
         end
      end
   catch e
      % Delete any channels that may have been added and then error.
      if ~isempty(chanindex)
         delchan = get(obj, channelprop);
         delete(delchan(chanindex))
      end      
      error('daq:addchannel:unexpected', e.message);
   end
end

% Restore the warning to its previous setting.
warning(warningState);

% Output the warning if the sample rate was changed by more than an
% insignificant amount.
sampleRateEpsilon = 0.001;
if abs(sampleRateBefore - uddobj.SampleRate) > sampleRateEpsilon
    warning('daq:daqmex:propertyConfigurationError', ...
'This hardware could not support the requested value of %.2f for SampleRate. SampleRate has been set to %.2f.', ...
        sampleRateBefore, uddobj.SampleRate)
end

% Construct the channel array from channel cell array.
chan = [chan{:}]';

% Reorder the channel objects if an index array was specified.
if ~isempty(index)
   if chanindex == index
      return;
   end
   
   % old_index is not a cell only if obj had one channel initially.
   if ~iscell(old_index),
      old_index = {old_index};
   end
   
   % Determine the new channel array order based on the old and new index.
   try
       new_index = localReorder(old_index, index);
   catch e
      % If an error occurred in localReorder, delete any channels that may have 
      % been added and then error.
      delchan = get(obj, channelprop);
      delete(delchan(chanindex))
      error('daq:addchannel:unexpected', e.message);
   end
      
   % Reorder the channel array.
   try
      reorderchannels(uddobj, new_index);
      chan = get(obj, channelprop);
   catch e
      % Delete the channels that have been added and error.
      delchan = get(obj, channelprop);
      delete(delchan(chanindex))
      error('daq:addchannel:unexpected', e.message);
   end
end


%*********************************************************************
% Determine the new order of the channel objects.
function temp = localReorder(old,new)

% Error if the indices are repeated.
if length(unique(new)) ~= length(new)
   error('daq:addchannel:unexpected','Unique indices must be specified.')
end

% Error if an index of zero or a negative index is given.
if (min(new)< 1)
   error('daq:addchannel:unexpected',...
       'Index values must be greater than or equal to 1.')
end

% Error if the indices do not increase.
if ~isempty(find(new - [0 new(1:end-1)] < 1, 1))
   error('daq:addchannel:unexpected','Index values must be increasing.')
end

% Create a dummy vector (temp) of zeros the length of the number 
% of objects to be included in the channel array.
old = [old{:}];
len = max(max([old new]), length([old new]));
temp = zeros(1,len);

% Fill in the dummy vector, temp, int he locations specified by the "new"
% vector of indices.
btemp = length(old)+1:length(old)+length(new);
temp(new) = btemp;

% Fill in the remaining locations of the dummy vector, temp, (those that
% currently contain zero) with the old indices.
i=find(temp==0);
temp(i(1:length(old)))=old;

% Determine if any zero's still exist.  If they do, then indices which
% contain a gap were provided and addchannel should error.
if ~isempty(find(temp == 0, 1))
   error('daq:addchannel:unexpected',...
       'Invalid INDEX provided.  The Channel array cannot contain gaps.');
end
