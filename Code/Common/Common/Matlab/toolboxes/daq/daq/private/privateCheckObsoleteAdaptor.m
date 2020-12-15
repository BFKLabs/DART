function privateCheckObsoleteAdaptor(objecttype, adaptor)
% PRIVATECHECKOBSOLETEADAPTOR Print a message regarding the obsolescence of an adaptor.
%
%   PRIVATECHECKOBSOLETEADAPTOR(OBJECTTYPE, ADAPTOR) prints a message 
%   warning the user that the adaptor passed in will become obsolete in a 
%   future release.
%   Details regarding how to get more information should be provided.
%

%   PRIVATECHECKOBSOLETEADAPTOR is a helper function for ANALOGINPUT,
%   ANALOGOUTPUT and DIGITALIO.
%
%   Copyright 2006-2008 The MathWorks, Inc.

% G426408, 426421 These adaptors on path to obsolescence.
traditionalNidaqAdaptorName = 'nidaq';
parallelAdaptorName = 'parallel';

% G426399, 426400 These adaptors obsolete.
keithleyAdaptorName = 'keithley';
hpe1432AdaptorName = 'hpe1432';

if (strcmpi(adaptor, keithleyAdaptorName))
  % If the adaptor is registered then it has been explicilty installed
  % so do not create the error. 
  if localIsAdaptorRegistered(adaptor)
      return
  end
  error(['daq:' objecttype ':adaptorobsolete'], ...
      ['The Keithley adaptor (''keithley'')is no longer part of Data\n'...
      'Acquisition Toolbox. It is now available on the MATLAB Central File Exchange.\n'...
      'Please see Solution 1-37TKH4 for details.']);
end

if (strcmpi(adaptor, hpe1432AdaptorName))
  % If the adaptor is registered then it has been explicilty installed
  % so do not create the error. 
  if localIsAdaptorRegistered(adaptor)
      return
  end
  error(['daq:' objecttype ':adaptorobsolete'], ...
      ['The VXI Technology adaptor (''hpe1432'') is no longer part of Data\n'...
      'Acquisition Toolbox. It is now available on the MATLAB Central File Exchange.\n'...
      'Please see Solution 1-37TX43 for details.']);
end

% Suppress the backtrace with this warning. When exiting restore to
% previous setting. According to the doc you can't save and restore
% backtrace state, so use the text returned by querying.
currentWarningState = evalc('warning query backtrace');
turnBackOn = false;
if strfind(currentWarningState, 'enabled')
    warning off backtrace;
    turnBackOn = true;
end

if (strcmpi(adaptor, parallelAdaptorName))
  warning(['daq:' objecttype ':adaptorobsolete'], ...
      ['This Parallel adaptor (''parallel'') will not be provided in future releases\n'...
      'of Data Acquisition Toolbox. Instead, it will be available as a separate download.\n'...
      'See Solution 1-5LI9OA for details.']);
end

if (strcmpi(adaptor, traditionalNidaqAdaptorName))
  warning(['daq:' objecttype ':adaptorobsolete'], ...
      ['Support for the National Instruments Traditional NI-DAQ driver will\n'...
      'not be provided in future releases of Data Acquisition Toolbox.\n'...
      'Instead, it will be available as a separate download.\n'...
      'Consider upgrading to the NI-DAQmx version if it supports your hardware.\n'...
      'See Solution 1-5LI9NF for details.']);
end

if turnBackOn
    warning on backtrace;
end

function isregistered = localIsAdaptorRegistered(adaptor)
    dhwinfo = daqhwinfo;
    isregistered = ~isempty(strmatch(adaptor, dhwinfo.InstalledAdaptors));
    
    

