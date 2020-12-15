function inspect(obj)
%INSPECT Open inspector and inspect data acquisition object properties.
%
%    INSPECT(OBJ) opens the property inspector and allows you to 
%    inspect and set properties for data acquisition object, OBJ. OBJ
%    must be a 1-by-1 data acquisition object.
%
%    Example:
%      % Inspect analog input properties.
%      obj = analoginput('mcc', 1);
%      inspect(obj)
%
%      % Inspect channel properties.
%      chan = obj.Channel;
%      inspect(chan(1));
%
%    See also DAQDEVICE/SET, DAQDEVICE/GET, DAQDEVICE/PROPINFO.
%

%    DTL 9-1-2004
%    Copyright 2004 The MathWorks, Inc.
%    $Revision: 1.1.6.1 $  $Date: 2004/12/01 19:46:47 $

% Error checking.
if length(obj)>1
   error('daq:inspect:OBJ1x1', 'OBJ must be a 1-by-1 data acquisition object.');
elseif ~isvalid(obj)
   error('daq:inspect:invalidOBJ', 'Data acquisition object OBJ is an invalid object.' );
end

% Open the inspector.
s = struct(obj);
inspect(s.uddobject);