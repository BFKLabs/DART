% Data Acquisition Toolbox CompactDAQ support
%
% National Instruments CompactDAQ hardware is supported in Data Acquisition
% Toolbox using the DAQ Session Based Interface.
%
% To control these data acquisition devices, you use a daq.Session object
% to configure and control one or more devices plugged into a CompactDAQ
% chassis. 
% 
% In a typical workflow, 
%    (1) Discover hardware devices using daq.getDevices
%    (2) Create a DAQ Session using daq.createSession
%    (3) Add device channels
%    (4) Set session and channel properties
%    (5) Perform on demand operations using inputSingleScan/outputSingleScan
%    (6) Perform clocked operations using startForeground/startBackground
%
% (1) Device enumeration and discovery:
%   <a href="matlab:help daq.getDevices">daq.getDevices</a> - Show data acquisition devices available
%   <a href="matlab:help daq.getVendors">daq.getVendors</a> - Show known data acquisition vendors
%   <a href="matlab:help daq.reset">daq.reset</a>      - Reinitialize all data acquisition devices and sessions.
%
% (2) Session creation:
%   <a href="matlab:help daq.createSession">daq.createSession</a> - Returns a DAQ session for a specific vendor
% 
% (3) Add device channels:
%   <a href="matlab:help daq.Session.addAnalogInputChannel">addAnalogInputChannel</a>   - Add an analog input channel. 
%   <a href="matlab:help daq.Session.addAnalogOutputChannel">addAnalogOutputChannel</a>  - Add an analog output channel. 
%   <a href="matlab:help daq.Session.addCounterInputChannel">addCounterInputChannel</a>  - Add a counter input channel. 
%   <a href="matlab:help daq.Session.addCounterOutputChannel">addCounterOutputChannel</a> - Add a counter output channel. 
%   <a href="matlab:help daq.Session.queueOutputData">queueOutputData</a>         - Queue data for output by hardware. 
%
% (4) Common session properties:
%   <a href="matlab:help daq.Session.Rate">Rate</a>              - Rate of operations, in scans per second.
%   <a href="matlab:help daq.Session.DurationInSeconds">DurationInSeconds</a> - Length of time the operation should occur, in seconds. 
%   <a href="matlab:help daq.Session.NumberOfScans">NumberOfScans</a>     - Number of scans that operation should execute.   
%   <a href="matlab:help daq.Session.Channels">Channels</a>          - Array of all channels associated with a session.   
% 
% (5) On demand operations
%   <a href="matlab:help daq.Session.inputSingleScan">inputSingleScan</a> - Immediately acquire a single scan across all input channels 
%   <a href="matlab:help daq.Session.outputSingleScan">outputSingleScan</a> - Immediately generate a single scan across all output channels 
%
% (6) Clocked operations
%   <a href="matlab:help daq.Session.startForeground">startForeground</a> - Begin clocked operations with hardware and return results. 
%   <a href="matlab:help daq.Session.startBackground">startBackground</a> - Begin background operations with hardware. 
% 
% Support and Service:
%   <a href="matlab:help daqsupport">daqsupport</a> - Generates text file summary of hardware information
%
% See also daq.getDevices, daq.createSession, daq.getVendors, daq.reset, daq.Session

% Copyright 2009-2011 The MathWorks, Inc.

