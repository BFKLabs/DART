function session = createSession(vendor,varargin)
%DAQ.CREATESESSION Create a data acquisition session for a given vendor
%   Returns a daq.Session object that represents a session with hardware
%   from the specific vendor.
%
% SESSION = DAQ.CREATESESSION(VENDOR_ID) returns a session object specific
% to the vendor ID specified by the string VENDOR_ID that you can configure to
% perform operations.  Type daq.getVendors() for a list of available
% vendors.
%
% Example:
%     s = daq.createSession('ni');
%     s.addAnalogInputChannel('cDAQ1Mod1', 'ai0', 'Voltage');
%     s.startForeground();
%
% See also DAQ.GETDEVICES, DAQ.GETVENDORS, DAQ.RESET

% Copyright 2010-2012 The MathWorks, Inc.

    try
        if nargin < 1 || ~ischar(vendor)
            error(message('daq:general:invalidCreateSessionParams'));
        end
        % Make sure that the HardwareInfo object is instantiated
        daq.HardwareInfo.getInstance();

        % g873066,873097,885613: Fixed LXE incompatibility warnings
        SessionManager = daq.internal.SessionManager.getInstance(); 
        session = SessionManager.getSessionFactory(vendor).createSession(varargin{:});
    catch e
        % Rethrow any errors as caller, removing the long stack of
        % errors -- capture the full exception in the cause field
        % if FullDebug option is set.
        if daq.internal.getOptions().FullDebug
            rethrow(e)
        end
        e.throwAsCaller()
    end
end

