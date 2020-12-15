function out=daqhwinfo(varargin)
%DAQHWINFO Return information on the available hardware.
%
% Note: For Session Based Interface, see <a href="matlab:help SESSIONBASEDINTERFACE">Session Based Interface</a>.
%
%    OUT = DAQHWINFO returns a structure, OUT, which contains data acquisition
%    hardware information.  This information includes the toolbox version,
%    MATLAB version and installed adaptors.
%
%    OUT = DAQHWINFO('ADAPTOR') returns a structure, OUT, which contains
%    information related to the specified adaptor, ADAPTOR.
%
%    OUT = DAQHWINFO('ADAPTOR','Property') returns the adaptor information for
%    the specified property, Property. Property must be a single string. OUT is
%    a cell array.
%
%    OUT = DAQHWINFO(OBJ) where OBJ is any data acquisition device object,
%    returns a structure, OUT, containing hardware information such as adaptor,
%    board information and subsystem type along with details on the hardware
%    configuration limits and number of channels/lines.  If OBJ is an array
%    of device objects then OUT is a 1-by-N cell array of structures where
%    N is the length of OBJ.
%
%    OUT = DAQHWINFO(OBJ, 'Property') returns the hardware information for the
%    specified property, Property.  Property can be a single string or a cell
%    array of strings.  OUT is a M-by-N cell array where M is the length of OBJ
%    and N is the length of 'Property'.
%
%    Example:
%      out = daqhwinfo
%      out = daqhwinfo('winsound')
%
%      ai  = analoginput('winsound');
%      out = daqhwinfo(ai)
%      out = daqhwinfo(ai, 'SingleEndedIDs')
%      out = daqhwinfo(ai, {'SingleEndedIDs', 'TotalChannels'})
%
% See also <a href="matlab:help daq">help daq</a>.
%

%    Copyright 1998-2012 The MathWorks, Inc.

try
    daq.internal.errorIfLegacyInterfaceUnavailable
catch e
    throwAsCaller(e);
end
    
% Adaptor names used by special case code
computerBoardsAdaptorName = 'cbi';
winsoundAdaptorName = 'winsound';
nidaqAdaptorName = 'nidaq';
nidaqmxAdaptorName = 'nidaqmx';

ArgChkMsg = nargchk(0,2,nargin); %#ok<NCHK>
if ~isempty(ArgChkMsg)
    error('daq:daqhwinfo:argcheck', ArgChkMsg);
end
if nargout > 1,
    error('daq:daqhwinfo:argcheck', 'Too many output arguments.')
end

% Register all UDD classes.
daqmex;

switch nargin
    case 0  % DAQ page
        try
            % Get the list of visible adaptors.
            adaptorName = dir(fullfile(toolboxdir('daq'),'daq','private','*.dll'));

            % Try to register. If can't, then ignore error as not all DLLs 
            % in the private directory represent adaptors with installed drivers.
            for adptLp=1:length(adaptorName),
                try
                    evalc('daqregister(adaptorName(adptLp).name);');
                catch %#ok<CTCH>
                end
            end

            adaptors = daq.engine.getadaptors();
        catch adaptorSetupException
            newException = MException('daq:daqhwinfo:unexpected', 'Getting list of adaptors');
            newException = newException.addCause(adaptorSetupException);
            throw(newException)
        end

        % Get a list of unique adaptors in nice format.
        adaptors = localGetAdaptors(adaptors);

        % Create the output structure.
        out.ToolboxName = 'Data Acquisition Toolbox';
        out.ToolboxVersion = localGetVersion('daq');
        out.MATLABVersion = localGetVersion('matlab');
        out.InstalledAdaptors = adaptors;

    case {1,2}  % Driver and Adaptor Page.
        if (~ischar(varargin{1}))
            error('daq:daqhwinfo:invalidadaptor', 'Invalid ADAPTOR specified.  Type ''daqhwinfo'' for a list of valid adaptors.')
        end

        adaptor = varargin{1};

        if strcmpi(adaptor,nidaqmxAdaptorName)
            % Geck 281433:  We explicitly block direct access to the NIDAQmx
            % adaptor in order to ensure that it's not an "undocumented" feature.
            error('daq:daqhwinfo:unexpected','Failure to find requested data acquisition device: nidaqmx.');
        end

        % Get the Adaptor information
        try
            out = localGetAdaptorInfo(adaptor);
        catch getInfoException
            try
                if exist(adaptor, 'file')==3 || exist(['mw', adaptor], 'file')==3
                    daqregister(adaptor);
                    out = localGetAdaptorInfo(adaptor);
                else
                    error('daq:daqhwinfo:unexpected', '%s', getInfoException.message)
                end
            catch registerException
                error('daq:daqhwinfo:unexpected', '%s', registerException.message)
            end
        end

        % If the customer has asked for a specific field, select that one from
        % the result
        if ( nargin == 2 )
            if (~ischar(varargin{2}))
                error('daq:daqhwinfo:invalidadaptor', 'Invalid ADAPTOR PROPERTY specified.  Type ''daqhwinfo(''ADAPTOR'')'' for a list of valid properties.')
            end
            property = varargin{2};
            out = localExtractProperty(out,property);
        end

end % case

    function [out] = localGetAdaptorInfo(adaptor)
        % Get the adaptor info. Special case code to provide backward
        % compatibility and handle special situations.

        if strcmpi(adaptor,nidaqAdaptorName)
            % Geck 281433:  In order to make NIDAQmx and NIDAQ adaptors look like a
            % single adaptor, we handle nidaq specially
            try
                out = localGetNIDAQAdaptorInfo;
            catch getInfoException
                throwAsCaller(getInfoException)
            end
            return
        end

        out = daq.engine.getadaptorinfo(adaptor);
    end % function localGetAdaptorInfo

    function [out] = localGetNIDAQAdaptorInfo
        % Get the nidaq adaptor info. Special case code to provide backward
        % compatibility and handle special situations.

        % Geck 281433:  In order to make NIDAQmx and NIDAQ adaptors look like a
        % single adaptor, we modify the results to report a single 'nidaq'
        % adaptor as follows:
        % Both NIDAQmx and NIDAQ Traditional are installed: Modify the NIDAQmx
        % to translate 'nidaqmx' to 'nidaq', and merge with NIDAQ results.
        % Only NIDAQmx is installed:  Modify the NIDAQmx results to translate
        % 'nidaqmx' to 'nidaq'.
        % Only NIDAQ is installed:  Just return NIDAQ results.
        % Neither is installed:  Throw an exception, since the user asked for
        % 'nidaq'

        % Get NIDAQmx results, and see if it's installed
        nidaqmxResults = [];
        try
            nidaqmxResults = daq.engine.getadaptorinfo(nidaqmxAdaptorName);
        catch exception  %#ok<NASGU>
            % If this fails, then the nidaqmx adaptor is not installed, which
            % in and of itself is not an error.
        end

        % Get NIDAQ results, and see if it's installed
        nidaqResults = [];
        try
            nidaqResults = daq.engine.getadaptorinfo(nidaqAdaptorName);
        catch exception %#ok<NASGU>
            % If this fails, then the nidaq adaptor is not installed, which
            % in and of itself is not an error.
        end

        if isempty(nidaqmxResults) && isempty(nidaqResults)
            % Neither nidaqmx nor nidaq is installed: throw an
            % exception, since the user asked for the 'nidaq' adaptor
            newException = MException('daq:daqhwinfo:nonidaq', 'No nidaq adaptors are installed.');
            throwAsCaller(newException);
        end

        if isempty(nidaqmxResults) && ~isempty(nidaqResults)
            % Only NIDAQ is installed -- just return those results
            out = nidaqResults;
            return;
        end

        % NIDAQmx is definitely installed.  Modify the NIDAQmx results to
        % make NIDAQmx results look like NIDAQ results
        out = nidaqmxResults;
        % Change the adaptorname from nidaqmx to nidaq
        out.AdaptorName = nidaqAdaptorName;
        % Change the constructors from nidaqmx to nidaq
        out.ObjectConstructorName = strrep(out.ObjectConstructorName,nidaqmxAdaptorName,nidaqAdaptorName);

        % is NIDAQ installed as well?
        if ~isempty(nidaqResults)
            % They are both installed.  Append the BoardNames,
            % InstalledBoardIds, and ObjectConstructorNameresult from the
            % 'nidaq' adaptor to the (modified) nidaqmx results
            out.BoardNames = [out.BoardNames nidaqResults.BoardNames];
            out.InstalledBoardIds = [out.InstalledBoardIds nidaqResults.InstalledBoardIds];
            out.ObjectConstructorName = [out.ObjectConstructorName;nidaqResults.ObjectConstructorName];
        end
        
        % When CompactDAQ devices are detected add an instruction on how to
        % get help.
        cDAQDevicesFound = false;
        devices = daq.getDevices;
        for dev = 1:length(devices)
            if isa(devices(dev), 'daq.ni.CompactDAQModule')
                 boardName = devices(dev).Model;
                 boardID = devices(dev).ID;
                 objectConstructorAI  = 'Requires DAQ Session Based Interface';
                 objectConstructorAO  = 'Requires DAQ Session Based Interface';
                 objectConstructorDIO = 'Requires DAQ Session Based Interface';
                 
                 out.BoardNames = [out.BoardNames boardName];
                 out.InstalledBoardIds = [out.InstalledBoardIds boardID];
                 out.ObjectConstructorName = vertcat(out.ObjectConstructorName, {objectConstructorAI, objectConstructorAO, objectConstructorDIO});
                 
                 cDAQDevicesFound = true;
            end
        end
        
        if cDAQDevicesFound
            warning off backtrace
            warning('daq:daqhwinfo:v3', 'Devices were detected that require the DAQ <a href="matlab:help SESSIONBASEDINTERFACE">Session Based Interface</a>.\nTo get device information in Session Based Interface see <a href="matlab:help DAQ.GETDEVICES">daq.getDevices</a>.\n');
            warning on backtrace
        end
        
    end % function localGetNIDAQAdaptorInfo

    function out = localGetAdaptors(adaptors)
        % Get the unique adaptor names.  Special case code to provide backward
        % compatibility and handle special situations.

        if ~isempty(adaptors)
            % Clear CBI out of the registry
            index = strmatch(computerBoardsAdaptorName, adaptors);
            if index
                try
                    daq.engine.unregisteradaptor(computerBoardsAdaptorName);
                    adaptors(index) = [];
                catch %#ok<CTCH>
                end
            end
            out = unique(lower(adaptors));
        else
            % Adaptors may be empty if the user has a wrong dll.
            % Try to register and create an object for 'winsound' and 'nidaq'.
            % If successful add to the out list.
            try
                winsound = daq.engine.getadaptorinfo(winsoundAdaptorName);
            catch %#ok<CTCH>
                winsound = [];
            end
            try
                nidaq = daq.engine.getadaptorinfo(nidaqAdaptorName);
            catch %#ok<CTCH>
                nidaq = [];
            end

            % Create the out list.
            out = {};
            if ~isempty(winsound)
                out = {winsoundAdaptorName};
            end
            if ~isempty(nidaq)
                out = {out{:}; nidaqAdaptorName};
            end

        end % if

        % Geck 281433:  In order to make NIDAQmx and NIDAQ adaptors look like a
        % single adaptor, we modify the results to report a single 'nidaq'
        % adaptor
        out = strrep(out,nidaqmxAdaptorName,nidaqAdaptorName);
        out = unique(out);
    end % function

    function str = localGetVersion(product)
        % Output the version of the toolbox.

        try
            % Get the version information.
            % Ex. Data Acquisition Toolbox Version 1.0 (R11) Beta 1 01-Sep-1998
            verinfo = ver(product);

            % Build the version string.
            str = [verinfo.Version,' ',verinfo.Release];
        catch %#ok<CTCH>
            str = '';
        end

    end % function localGetAdaptors

    function [out] = localExtractProperty(out,property)
        try
            out = out.(property);
        catch %#ok<CTCH>
            error('daq:daqhwinfo:invalidadaptor', 'Invalid ADAPTOR PROPERTY specified.  Type ''daqhwinfo(''ADAPTOR'')'' for a list of valid properties.')
        end
    end % function localExtractProperty

end % function DAQHWINFO

