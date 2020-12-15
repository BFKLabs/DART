function daqreset
%DAQRESET Delete and unload all data acquisition objects and DLLs.
%
%    DAQRESET deletes any data acquisition objects existing in the
%    engine as well as unloads all DLLs loaded by the engine.  The
%    adaptor DLLs and daqmex.dll are also unlocked and unloaded.  As
%    a result, the data acquisition hardware is reset.
%
%    DAQRESET is the data acquisition command that returns MATLAB to 
%    the known state of having no data acquisition objects and no 
%    loaded data acquisition DLLs.
%
%    See also DAQHELP, DAQDEVICE/DELETE.
%

%    MP 01-05-99   
%    Copyright 1998-2010 The MathWorks, Inc.
%    $Revision: 1.10.2.10 $  $Date: 2013/05/13 22:13:06 $

[~,loadedMex] = inmem;
if any(strcmpi(loadedMex,'daqmex'))
   daqmex('reset');
   builtin('clear','daqmex');
end

% Reset the session based interface as well
daq.reset
