%ErrorOccurred event is fired when a hardware error occurs on a device.
%
% Listeners on the ErrorOccurred event of the daq.Session object will
% receive a call to their listener function with a
% daq.ErrorOccurredInfo object as the second parameter.
%
% Properties of ErrorOccurredInfo:
%     Error : The MException associated with the error
%
% Example:
%    s = daq.createSession('ni');
%    s.addAnalogInputChannel('cDAQ1Mod1', 'ai0', 'Voltage');
%    lh1 = s.addlistener('DataAvailable', @(src,event) plot(event.Data));
%    lh2 = s.addlistener('ErrorOccurred', @(src,event) ...
%        disp(event.Error.getReport()));
%    s.startBackground();
%    delete(lh1);
%    delete(lh2);
%
% See also handle.addlistener, MException, <a href="matlab:help daq.DataAvailable">DataAvailable</a>, <a href="matlab:help daq.DataRequired">DataRequired</a>, <a href="matlab:help daq.Session.startBackground">startBackground</a>

%   Copyright 2010 The MathWorks, Inc.
