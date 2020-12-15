% When performing clocked acquisitions in the background, the
% DataAvailable event is fired when there is acquired
% analog/counter input data to be processed. Clocked digital input
% operations are not currently supported.
%
% Listeners on the DataAvailable event of the daq.Session object will
% receive a call to their listener function with a
% daq.DataAvailableInfo object as the second parameter (EVENTINFO).
%
% Properties of DataAvailableInfo:
%      Data        : An mxn array where m is the number of scans, 
%                    and n is the number of channels.
%      TimeStamps  : An mx1 array of time stamps.
%      TriggerTime : A MATLAB serial date number of the absolute time 
%                    of TimeStamp(1).
%
% Example:
%     s = daq.createSession('ni');
%     s.addAnalogInputChannel('cDAQ1Mod1', 'ai0', 'Voltage');
%     lh = s.addlistener('DataAvailable', ...
%         @(src,event) plot(event.TimeStamps, event.Data));
%     s.startBackground();
%     delete(lh);
%
% See also handle.addlistener, <a href="matlab:help daq.DataRequired">DataRequired</a>, <a href="matlab:help daq.Session.startBackground">startBackground</a>

%   Copyright 2010-2012 The MathWorks, Inc.
