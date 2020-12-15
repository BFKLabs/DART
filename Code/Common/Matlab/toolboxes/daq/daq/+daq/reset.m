function reset()
%DAQ.RESET Reset the data acquisition toolbox and delete all DAQ objects
%
% Example:
% daq.reset
%
% See also DAQ.GETDEVICES, DAQ.GETVENDORS, DAQ.CREATESESSION

% Copyright 2009-2012 The MathWorks, Inc.

% releasing the instance of the class manager deletes all DAQ objects that monitor it.
instance = daq.internal.ClassManager.getInstance();
instance.releaseInstance();

% reset the options associated with the daq system
daq.internal.getOptions('reset');
end

