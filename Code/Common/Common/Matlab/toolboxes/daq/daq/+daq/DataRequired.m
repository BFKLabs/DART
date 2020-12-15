% When performing clocked signal generation in the background, the
% DataRequired event is fired when additional analog/counter data
% is required for output on a continuous operation. Clocked digital
% output operations are not currently supported.
%
% Listeners to the DataRequired event will receive a callback every time 
% the device runs low on data. The callback is used to queue more data 
% to the device.
%
% Example:
%     s = daq.createSession('ni');
%     s.addAnalogOutputChannel('cDAQ1Mod2', 'ao0', 'voltage');
%     s.IsContinuous = true;
%     data = sin(linspace(0, 2*pi, 1001))';
%     data(end) = [];
%     s.queueOutputData(data);
%     lh = s.addlistener('DataRequired', ...
%         @(src,event) src.queueOutputData(data));
%     s.startBackground();
%     delete(lh);
%
% See also: handle.addlistener, <a href="matlab:help daq.DataAvailable">DataAvailable</a>,  <a href="matlab:help daq.Session.startBackground">startBackground</a>

%   Copyright 2010-2012 The MathWorks, Inc.
