function varargout=getdata(obj,varargin)
%GETDATA Return acquired data samples from engine to MATLAB workspace.
%
%    DATA = GETDATA(OBJ) returns the number of samples specified in the
%    SamplesPerTrigger property of analog input object OBJ.  DATA is a
%    M-by-N matrix where M is the number of samples returned and N is the
%    number of channels in OBJ.  OBJ must be a 1-by-1 analog input object.
%
%    DATA = GETDATA(OBJ, SAMPLES) returns the specified number, SAMPLES, 
%    of data.
% 
%    [DATA, TIME] = GETDATA(OBJ) returns the number of samples specified 
%    in the SamplesPerTrigger property of analog input object OBJ in 
%    time-value pairs. TIME is a M-by-1 matrix where M is the number of 
%    samples returned.
%
%    [DATA, TIME] = GETDATA(OBJ,SAMPLES) returns the specified number, 
%    SAMPLES, of data in time-value pairs.
%
%    DATA = GETDATA(OBJ, SAMPLES, TYPE)
%    [DATA, TIME] = GETDATA(OBJ, SAMPLES, TYPE) allows for DATA to be 
%    returned as the data type specified by the string TYPE.  TYPE can
%    either be 'double', for data to be returned as doubles, or 'native',
%    for data to be returned in its native data type.  If TYPE is not
%    specified, 'double' is used as the default.
%
%    [DATA, TIME, ABSTIME] = GETDATA(...) returns the absolute time ABSTIME  
%    of the trigger, which can also be found in OBJ's InitialTriggerTime
%    property.  ABSTIME is returned as a CLOCK vector.
%
%    [DATA, TIME, ABSTIME, EVENTS] = GETDATA(...) returns the structure
%    EVENTS which contains a list of events that occurred during the time
%    period of the samples extracted.
%
%    [DATA,...] = GETDATA(OBJ, 'P1', V1, 'P2', V2,...) specifies the 
%    the number of samples to be returned, the format of the
%    DATA matrix and whether to return a time series collection object.
%
%      Valid Property Names (P1, P2,...) and Property Values (V1, V2,...)
%      include:
%
%         Samples      -  [number of samples to return]
%         DataFormat   -  [ {double} | native ]
%         OutputFormat -  [ {matrix} | tscollection ]
%
%      The default values for the DataFormat and OutputFormat
%      properties are indicated by braces {}.  The default value for
%      Samples is the number of samples specified in the SamplesPerTrigger 
%      property of analog input object OBJ.
%
%      Setting the OutputFormat property to 'tscollection' causes GETDATA
%      to return a time series collection object.  In this case, only the
%      DATA left hand argument is used.
%
%    GETDATA is a blocking function that returns execution control to the 
%    MATLAB workspace once the requested number of samples become
%    available. OBJ's SamplesAvailable property will automatically be
%    reduced by the number of samples returned by GETDATA.  If the
%    requested number of samples is greater than the samples to be
%    acquired, then an error is returned.
%
%    TIME=0 is defined as the point at which data logging begins, i.e.,
%    OBJ's Logging property is set to 'On'.  TIME is measured continuously,
%    in seconds, with respect to 0 until the acquisition is stopped, i.e.,
%    OBJ's Running property is set to 'Off'.
%
%    If GETDATA returns data from multiple triggers in a matrix, the data
%    from each trigger is separated by a NaN.  This will increase the
%    length of DATA and TIME by the number of triggers.  If multiple
%    triggers occur, ABSTIME, is the absolute time of the first trigger.
%
%    If GETDATA returns a time series collection object, DATA will contain
%    an absolute time series object for each channel in OBJ, with time=0
%    set to InitialTriggerTime property of OBJ. Each time series object is
%    given a name corresponding to the ChannelName property of the channel.
%    If this name cannot be used as a time series object name, the name
%    will be set to 'Channel' with the HwChannel property of the channel
%    appended. If the DataFormat property is set to 'double', each time
%    series object in the collection will have the Units field of its
%    DataInfo property set to the Units property of the corresponding
%    channel in OBJ.  If the DataFormat property is set to 'native', the
%    Units property is set to 'native'.  In addition, each time series
%    object will have tsdata.event objects attached corresponding to the
%    log of events associated with OBJ. If GETDATA returns data from
%    multiple triggers, the data from each trigger is separated by a NaN in
%    the time series data.  This will increase the length of data and time
%    vectors in the time series object by the number of triggers.  
%
%    It is possible to issue a ^C (Control-C) while GETDATA is blocking.
%    This will not stop the acquisition but will return control to MATLAB.
%
%    See also DAQHELP, FLUSHDATA, GETSAMPLE, PEEKDATA, PROPINFO, TIMESERIES, TSCOLLECTION.
%

%    DTL 9-1-2004
%    Copyright 1998-2009 The MathWorks, Inc.
%    $Revision: 1.10.2.16 $  $Date: 2009/05/14 16:49:07 $

% Check for device arrays.
if ( length(obj) > 1 )
   error('daq:getdata:invalidobject', 'OBJ must be a 1-by-1 analog input object.');
end
 
% Check for an analog input object.
if ~isa(obj, 'analoginput') 
   error('daq:getdata:invalidobject', 'OBJ must be a 1-by-1 analog input object.');
end

% Determine if the object is valid.
if ~all(isvalid(obj))
   error('daq:getdata:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Default parameters
samples = get(obj,'SamplesPerTrigger');
dataformat = 'double';
outputformat = 'matrix';

% Error if SAMPLES is not a non-negative numeric scalar.
if ( nargin > 1 )
    if ischar(varargin{1})
        % For historical/backwards compatibility reasons, TYPE might be
        % specified here.  Handle specially if this is a valid TYPE string
        if strncmpi(varargin{1}, 'double', length(varargin{1})) || ...
            strncmpi(varargin{1}, 'native', length(varargin{1}))
            dataformat = varargin{1};
        else
            % If varargin{1} is char, then assume PV pairs.
            [samples,dataformat,outputformat]=localParseInput(obj,varargin{:});
        end
    else
        samples = varargin{1};
        if ~isnumeric(samples) || ~isscalar(samples) || samples <= 0
           error('daq:getdata:invalidsamples', 'SAMPLES must be a scalar value greater than 0.');
        end
        if ( nargin > 2 )
            dataformat = varargin{2};
            % Error if an invalid TYPE is specified.
            if ~strncmpi(dataformat, 'double', length(dataformat)) && ...
                ~strncmpi(dataformat, 'native', length(dataformat))
                error('daq:getdata:invalidformat', 'TYPE can be either ''double'' or ''native''.');
            end
        end
    end
end

% Enforce the restriction that only one left hand arg is valid when
% outputformat is tscollection
if nargout ~= 1 && strncmpi(outputformat, 'tscollection', length(outputformat))
    error('daq:getdata:onlydatareturned','Only 1 left hand argument can be specified when ''OutputFormat'' is set to ''tscollection''.')
end

% Assign the output arguments based on nargout.
% D = GETDATA(...)
nout=nargout;
uddobj = daqgetfield(obj,'uddobject');
if (nout<=1)
    % If outputformat is tscollection, generate a tscollection
    if strncmpi(outputformat, 'tscollection', length(outputformat))
        [data,time,abstime,events]=getdata(uddobj,samples,dataformat);
        objinfo.samplerate = get(obj,'SampleRate');
        % Geck 343407: Need to do different things if there is only one
        % channel.  get(get(obj,'Channel'),<propname>) returns a cell
        % array if there is more than one channel, but does not if
        % there is only one.
        channels = get(obj,'Channel');
        if length(channels) == 1
            objinfo.channelnames = {get(channels,'ChannelName')};
            objinfo.hwids = get(channels,'HwChannel');
            if strncmpi(dataformat, 'double', length(dataformat))
                % if the customer asks for 'double' data, set the data units to
                % whatever is set in the object (like 'Volts).
                objinfo.channelunits = {get(channels,'Units')};
            else
                % if the customer asks for 'native' data, set the data units to
                % 'native'
                objinfo.channelunits = {'native'};
            end
        else
            objinfo.channelnames = get(channels,'ChannelName');
            objinfo.hwids = cell2mat(get(channels,'HwChannel'));
            if strncmpi(dataformat, 'double', length(dataformat))
                % if the customer asks for 'double' data, set the data units to
                % whatever is set in the object (like 'Volts).
                objinfo.channelunits = get(channels,'Units');
            else
                % if the customer asks for 'native' data, set the data units to
                % 'native'.  See the help for DEAL for an explanation
                % of this method to create and set the cell array.
                [objinfo.channelunits{1:length(channels)}] = deal('native');
            end
        end
        varargout{1} = daqgate('privateCreateTimeSeriesCollection',...
                                objinfo,data,time,abstime,events);
    else
        varargout{1}=getdata(uddobj,samples,dataformat);
    end
else
    % [D,T]= GETDATA(...)
    [varargout{1:nout}]=getdata(uddobj,samples,dataformat);
end

    % *********************************************************************
    % Parse the input to determine the PV pairs specified.
    function [samples,dataf,outputf]=localParseInput(obj,varargin)

        % Initialize variables.
        pv = varargin;
        samples = get(obj,'SamplesPerTrigger');
        dataf = 'double';
        outputf = 'matrix';

        % Error if invalid PV pairs were passed.
        if rem(length(pv), 2) ~= 0
            error('daq:getdata:invalidproperty','Invalid Property-Value pairs supplied to GETDATA.');
        end

        % Determine what properties were specified and it's value.
        for iPV = 1:2:length(pv)
            if strncmpi(pv{iPV}, 'samples', length(pv{iPV}))
                samples = pv{iPV+1};
                if ~isnumeric(samples) || ~isscalar(samples) || samples < 0
                    error('daq:getdata:invalidsamples', 'SAMPLES must be a non-negative scalar value.');
                end
            elseif strncmpi(pv{iPV}, 'dataformat', length(pv{iPV}))
                dataf = pv{iPV+1};
                % Error if an invalid DataFormat is specified.
                if ~strncmpi(dataf, 'double', length(dataf)) && ...
                    ~strncmpi(dataf, 'native', length(dataf))
                    error('daq:getdata:invalidformat', '''DataFormat'' can be either ''double'' or ''native''.');
                end
            elseif strncmpi(pv{iPV}, 'outputformat', length(pv{iPV}))
                outputf = pv{iPV+1};
                % Error if an invalid OutputFormat is specified.
                if ~(strncmpi(outputf, 'matrix', length(outputf)) || ...
                    strncmpi(outputf, 'tscollection', length(outputf)))
                    error('daq:getdata:invalidoutputformat', '''OutputFormat'' can be either ''matrix'' or ''tscollection''.');
                end
            else
                % Error if an invalid property is specified.
                error('daq:getdata:invalidproperty','Invalid property specified to GETDATA.');
            end
        end % for iPV = 1:2:length(pv)
    end % localParseInput
end % getdata