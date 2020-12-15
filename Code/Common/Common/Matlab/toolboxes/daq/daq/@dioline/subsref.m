function result = subsref(obj, Struct)
%SUBSREF Reference into data acquisition objects.
%
%    Supported syntax for device objects:
%    a = ai.samplerate;       calls    get(ai,'samplerate');
%    a = ai.channel;          calls    get(ai,'channel');
%    a = ai.channel(1:2);     calls    get(ai,'channel',[1 2]);
%    a = ai.channel(3).Units; calls    get(get(ai,'channel',3), 'Units');
%    a = ai.channel.Units;    calls    get(get(ai,'channel'), 'Units');                                  
%
%    Supported syntax for channels or lines:
%    a = obj.Units;               calls    get(obj,'Units');
%    a = obj(1:2).SensorRange;    calls    get(obj(1:2),'SensorRange');
%
%    See also DAQDEVICE/GET, ANALOGINPUT, ANALOGOUTPUT, DIGITALIO, PROPINFO, 
%    ADDCHANNEL, ADDLINE.
%

%    MP 3-26-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.9.2.7 $  $Date: 2008/06/16 16:35:54 $

% Initialize variables
StructL = length(Struct);

% Parse the input into PROP1 and INDEX.
try
   [prop1, index] = daqgate('privateparsechild',obj,Struct);
catch e
   error('daq:subsref:unexpected', e.message)
end

% Return empty brackets if the index is empty.
if isempty(index) 
   result = [];
   return;
end

% From the parsed input, obtain the information.
switch StructL
case 1
   if isempty(prop1)
      % chan([1 3])
	  % Check to see that object is a vector array
      if length(index{1}) ~= numel(index{1})
		  error('daq:subsref:size', 'Only a row or column vector of device objects can be created.')
      end
	  
      try
         uddobjs = obj.uddobject;
         obj.uddobject = uddobjs(index{1});
         result = obj;
      catch e
         error('daq:subsref:unexpected', e.message)
      end
   else
      % INDEX = [], PROP1 = 'Property Name'
      % chan.ChannelName
      % result contains the property information.
      try
         result = get(obj, prop1);
      catch e
        localHandleError(e);
      end
   end
case 2
   % chan(1:2).ChannelName
   try
      % Check to see that index{1} is a vector.
      if length(index{1}) ~= numel(index{1})
		  error('daq:subsref:size', 'Only a row or column vector of objects can be created.')
      end
      
      % Obtain the constructor name (aichannel, aochannel, dioline)
      % and pass the handle to the constructor to get the specific
      % channel or line object.
      h = struct(obj);
      constr = class(obj);
      h1 = feval(constr, h.uddobject(index{1}(:)));
      % result contains property information. 
      result = get(h1, prop1);
   catch e
      localHandleError(e);
   end
otherwise  
   error('daq:subsref:invalidsyntax', 'Invalid syntax: Too many subscripts.')
end

% *************************************************************************
% Remove any extra carriage returns.
function localHandleError(e)

errmsg = e.message;

while errmsg(end) == sprintf('\n')
   errmsg = errmsg(1:end-1);
end

throwAsCaller(MException('daq:subsref:unexpected',errmsg));
