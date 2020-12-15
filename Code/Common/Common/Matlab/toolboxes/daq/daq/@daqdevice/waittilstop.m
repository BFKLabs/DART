function waittilstop(obj, waittime)
%WAITTILSTOP Wait for the data acquisition object to stop running.
%
% WAITTILSTOP has been renamed to WAIT.  WAITTILSTOP still works but may be
%    removed in the future.  Use WAIT instead.
%
%    See also DAQDEVICE/WAIT
%

%    DTL 9-1-2004
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.6.2.7 $  $Date: 2004/12/01 19:47:22 $

warning('daq:waittilstop:obsoletefunction','The WAITTILSTOP function is obsolete. Use WAIT instead.');
wait(obj,waittime);
