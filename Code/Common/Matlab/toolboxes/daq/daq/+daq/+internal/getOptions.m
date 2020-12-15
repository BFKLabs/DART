function varargout = getOptions(varargin)
%getOptions Returns the current set of active options for Session-based interface
%   [options] = getOptions(option1name, option1setting,...) returns a structure, OPTIONS, that
%   contains the currently selected options for the Data Acquisition
%   Toolbox Session-based interface.  Each option is set using the
%   following sequence:
%     1. The default setting for the option
%     2. The options setting in the file daqOptions.mat in the present
%        working directory.  See notes for details
%     3. The options specified as PV pairs parameter to getOptions
%   These options are determined ONCE per session.  All subsequent calls
%   to getOptions will return the cached options.
%
%    getOptions('reset') reset the cached options.  The next call to
%    getOptions will cause all options to be reevaluated.  A call to
%    daq.reset() causes this to be executed.
%
%    Note:  The daqOptions.mat file contains a single variable, "options"
%    which is a structure with fields matching the various options.  If a
%    field is not specified, then the default value is used.

% Copyright 2010-2013 The MathWorks, Inc.
%

persistent options;

% if there is one RHS arg, 'reset', then force a cache reset
if nargout == 0 && nargin==1 && strcmpi(varargin{1},'reset')
    options = [];
    return
end

if ~isempty(options)
    % if options is not empty, then return it (it's the cached result)
    varargout{1} = options;
    return
end

% Define default options
defaultOption.UnitTestMode = false;
defaultOption.DemoMode = false;
defaultOption.NoDevices = false;
defaultOption.NoVendors = false;
defaultOption.FullDebug = false;
defaultOption.StateDebug = false;
defaultOption.CompactDAQOnly = false;
defaultOption.DisableReferenceClockSynchronization = false;
defaultOption.SupportedSpecializedMeasurements = {'Voltage','Current','Thermocouple','Accelerometer', 'RTD','Bridge','Microphone','IEPE'};
defaultOption.SupportedCounterMeasurements = {'EdgeCount','PulseWidth','Frequency','Position','PulseGeneration'};
defaultOption.SupportedDigitalMeasurements = {'InputOnly','OutputOnly','Bidirectional'};
defaultOption.SupportedAudioMeasurements = {'Audio'};
defaultOption.SupportedTriggerConnectionTypes = {'StartTrigger'};
defaultOption.SupportedClockConnectionTypes = {'ScanClock'};
defaultOption.SupportedPlatforms = {'win32', 'win64'};

% Determine the expected location of the daqOptions.mat file
optionFilePath = fullfile(pwd,'daqOptions.mat');

% Load daqOptions.mat file from current directory
try
    if exist(optionFilePath,'file') == 2
        optionsFromFile = load(optionFilePath);
        optionsFromFile = optionsFromFile.options;
        
        % Merge the options from the file onto the default options, so
        % that option files only need specify the desired options
        fieldsFromFile = fields(optionsFromFile);
        for iField = 1:numel(fieldsFromFile)
            defaultOption.(fieldsFromFile{iField}) =...
                optionsFromFile.(fieldsFromFile{iField});
        end
    end
catch %#ok<CTCH>
    % Any error is ignored.
end

% Parse the input parameters
p = inputParser();

% If true, DAQ is set up for unit tests, meaning that ONLY the
% test adaptors will be loaded.
p.addParamValue('UnitTestMode', defaultOption.UnitTestMode, @islogical);

% If true, DAQ is set up for demo mode, meaning that ONLY the
% demo adaptors will be loaded, which are normally in
% [MATLABROOT]\toolbox\daq\daqdemos\demoadaptors\+daq
p.addParamValue('DemoMode', defaultOption.DemoMode, @islogical);

% If true, DAQ simulates finding no devices.
p.addParamValue('NoDevices', defaultOption.NoDevices, @islogical);

% If true, DAQ simulates finding no vendors.
p.addParamValue('NoVendors', defaultOption.NoVendors, @islogical);

% If true, DAQ will error on a failed adaptor load (usually,
% that is ignored.)
p.addParamValue('FullDebug', defaultOption.FullDebug, @islogical);

% If true, DAQ will display session and channel group state change on the
% command line.
p.addParamValue('StateDebug', defaultOption.StateDebug, @islogical);

% If true, NI adaptor will only allow channels from CompactDAQ
% hardware to be listed by getDevices.
p.addParamValue('CompactDAQOnly', defaultOption.CompactDAQOnly, @islogical);


p.addParamValue('DisableReferenceClockSynchronization', defaultOption.DisableReferenceClockSynchronization, @islogical);

% Limits channel types to those in this cell array of strings.
% {'all'} disables this check
p.addParamValue('SupportedSpecializedMeasurements',...
    defaultOption.SupportedSpecializedMeasurements, @iscellstr);
p.addParamValue('SupportedDigitalMeasurements',...
    defaultOption.SupportedDigitalMeasurements, @iscellstr);
p.addParamValue('SupportedCounterMeasurements',...
    defaultOption.SupportedCounterMeasurements, @iscellstr);
p.addParamValue('SupportedAudioMeasurements',...
    defaultOption.SupportedAudioMeasurements, @iscellstr);

% Limits trigger and clock connections to those in this cell array of
% strings. {'all'} disables this check
p.addParamValue('SupportedTriggerConnectionTypes',...
    defaultOption.SupportedTriggerConnectionTypes, @iscellstr);
p.addParamValue('SupportedClockConnectionTypes',...
    defaultOption.SupportedClockConnectionTypes, @iscellstr);
% Toolbox initialization will fail on any platform other than those in this cell array of strings.
% {'all'} disables this check.  Use strings returned by
% computer('arch')
p.addParamValue('SupportedPlatforms',...
    defaultOption.SupportedPlatforms, @iscellstr);

p.parse(varargin{:});

% Cache the results
options = p.Results;

% return the results
varargout{1} = options;

end

