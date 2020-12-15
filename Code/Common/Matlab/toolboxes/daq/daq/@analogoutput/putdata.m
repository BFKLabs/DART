function putdata(obj,data)
%PUTDATA Queue data samples to engine for output.
%
%    PUTDATA(OBJ,DATA) outputs source data specified in the matrix DATA to
%    the hardware associated with 1-by-1 analog output object OBJ. DATA can
%    consist of doubles or native data types but cannot contain NaNs.  DATA
%    must contain a column of data for each channel contained in OBJ.
%
%    PUTDATA(OBJ,TS) outputs source data specified in the time series
%    object TS to the hardware associated with 1-by-1 analog output object
%    OBJ with a single channel.  TS must contain a single vector of data to
%    be output.  TS must have a TimeInfo.Units of 'seconds' and IsTimeFirst
%    must be 1.
%
%    PUTDATA(OBJ,TSC) outputs source data specified in the time series
%    collection TSC to the hardware associated with 1-by-1 analog output
%    object OBJ where the number of channels matches the number of time
%    series in TSC.  The time series in TSC are mapped to channels in the
%    analog output object using their ordinal order in the collection (i.e.
%    tsc(:,1), tsc(:,2), etc. Each time series in TSC must contain a single
%    vector of data to be output.  TSC must have a TimeInfo.Units of
%    'seconds' and all time series objects in TSC must have IsTimeFirst set
%    to 1.
%
%    If TSC or TS contains NaN, gaps, or is sampled at a different rate
%    than the SampleRate of OBJ, the data will be resampled at the rate of
%    OBJ using the interpolation mode for that time series
%    (DataInfo.Interpolation).  
%
%    If TSC or TS contains any data points that are not within the
%    UnitsRange of the channel it pertains to, the data points will be
%    clipped to the bounds of the UnitsRange property.
%
%    PUTDATA can be used to queue data in memory before the START command 
%    is issued, or it can be used to directly output data after START has 
%    been issued.  In either case, no data is output until the trigger
%    occurs. If PUTDATA is called before START is issued, then data is
%    queued to memory until:
%       1) OBJ's MaxSamplesQueued is reached.  If this value is exceeded,
%          an error will occur.
%       2) The limitations of your hardware and computer are reached.
%
%    If the value of the RepeatOutput property is greater than 0, then all 
%    data queued before START is issued will be requeued (repeated) until
%    the RepeatOutput value is reached.
%
%    If PUTDATA is called after START is issued, then the RepeatOutput
%    property cannot be used. If MaxSamplesQueued is exceeded, PUTDATA
%    becomes a blocking function until there is enough space in the queue
%    to add the additional data. 
%
%    It is possible to issue a ^C (Control-C) while PUTDATA is blocking.
%    This stops the data from being added to the queue.  It does not stop
%    data from being output.
%
%    As soon as a trigger occurs, samples can be output.  The SamplesOutput
%    property keeps a running count of the total number of samples per
%    channel that have been output. Additionally, the SamplesAvailable
%    property tells you how many samples are ready to be output from the
%    engine per channel. When data is output, SamplesAvailable is reduced
%    by the number of samples sent to the hardware.
%
%    See also DAQHELP, PUTSAMPLE, DAQDEVICE/START, PROPINFO, TIMESERIES, TSCOLLECTION.
%

%    DTL 9-1-2004
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.12.2.9 $  $Date: 2008/06/16 16:34:50 $


% Check for device arrays.
if ( length(obj) > 1 )
   error('daq:putdata:unexpected', 'OBJ must be a 1-by-1 analog output object.');
end
 
% Check for an analog output object.
if ~isa(obj, 'analogoutput') 
   error('daq:putdata:invalidobject', 'OBJ must be a 1-by-1 analog output object.');
end

% Determine if the object is valid.
if ~all(isvalid(obj))
   error('daq:putdata:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Check for numeric sample data, time series collection, or time series.
if ~isnumeric(data) && ~isa(data,'tscollection') && ~isa(data,'timeseries')
    error('daq:putdata:invaliddata', 'DATA must be doubles, native numeric values, a time series collection, or a time series object.');
end

if (isa(data,'tscollection') || isa(data,'timeseries'))
    % Validate that there are as many time series as channels
    numChannels = length(get(obj,'Channel'));
    if isa(data,'tscollection') 
        if size(data,2) ~= numChannels
            error('daq:putdata:invalidtscount','The number of time series objects in TSC must match the number of channels in OBJ.');
        end
    else
        if numChannels ~= 1
            error('daq:putdata:onechannelwithts','OBJ must have only 1 channel when TS is a time series object.  You must use a time series collection when you have more than one channel.');
        end
    end
    
    % If it's a tscollection or timeseries, render the data to a matrix
    localValidateTSData(data);
    data = localRenderTSToMatrix(data,get(obj,'SampleRate'));
end

uddobj = daqgetfield(obj,'uddobject');
putdata(uddobj,data);

    % *********************************************************************
    % Render a timeseries or tscollection to a matrix.
    function [data] = localRenderTSToMatrix(data,targetRate)

        % Resample the timeseries to match the object sample rate
        data = localResampleTSIfNeeded(data,targetRate);

        % Get the data out of the tscollection or timeseries
        data = localExtractTSData(data);
    end

    % *********************************************************************
    % Resample the timeseries or tscollection if it has gaps or doesn't
    % match the target rate.
    function [data] = localResampleTSIfNeeded(data,targetRate)
        % resample if the frequency is different
        resampleNeeded = false;
        %Turn off warning backtrace
        s = warning('off','backtrace');
        if isnan(data.TimeInfo.Increment) || localIsNansInTSData(data)
            warning('daq:putdata:gapsremoved','TS/TSC has been resampled to remove gaps or timestamps that are not uniformly sampled.');
            resampleNeeded = true;
        else
            % resample if  the time series collection is on a non-uniform timebase, or 
            % there are gaps in the data
            if targetRate ~= 1/data.TimeInfo.Increment
                warning('daq:putdata:resampled','TS/TSC has been resampled to match the sample rate of OBJ.');
                resampleNeeded = true;
            end
        end
        warning(s);

        % resample if needed
        if resampleNeeded
            % Calculate the new time base
            newTime = (data.TimeInfo.Start:1 / targetRate:data.TimeInfo.End)';
            data = resample(data,newTime);
        end
    end %localResampleIfNeeded

    % *********************************************************************
    % Check data in the timeseries or tscollection for NaNs
    function [nansPresent] = localIsNansInTSData(tsc)
        if isa(tsc,'timeseries')
            % If it's a timeseries object, then it's easy to detect if
            % there are nans.
            nansPresent = any(isnan(tsc.Data));
            return 
        end
        % It's a tscollection: Iterate over the timeseries in the
        % tscollection.  Assume we won't find any Nans
        nansPresent = false;
        tsNames = gettimeseriesnames(tsc);
        numTS = length(tsNames);
        for iTS = 1:numTS
            % check each timeseries in the collection.
            if any(isnan(get(get(tsc,tsNames{iTS}),'Data')))
                % Found a Nan -- we're done.
                nansPresent = true;
                return
            end
        end % for iTS
    end % localIsNansInTSData

    % *********************************************************************
    % Extract data from the timeseries or tscollection 
    function [data] = localExtractTSData(tsc)

        if isa(tsc,'timeseries')
            % If it's just a timeseries, get the data directly.
            data = tsc.Data;
            return;
        end %if isa(tsc,'timeseries')

        tsNames = gettimeseriesnames(tsc);
        numTS = length(tsNames);
        %Build a single M x N array, with M samples, and N channels
        % Preallocate samples for speed
        data = zeros(tsc.TimeInfo.length,numTS);
        for iTS = 1:numTS
            % pull the timeseries out of the collection.
            ts = get(tsc,tsNames{iTS});
            
            % Copy a single time series out into a column in data
            data(:,iTS) = ts.Data;
        end % for iTS
    end %localExtractData

    % *********************************************************************
    % Validate that the time series or time series collection object is OK.  Error if it isn't
    function localValidateTSData(tsc)
        % the time series or time series collection must be in seconds
        if ~strcmpi(data.TimeInfo.Units,'seconds')
            error('daq:putdata:tsmustbeseconds', 'TS/TSC must have a TimeInfo.Units of ''seconds''.');
        end

        if isa(tsc,'timeseries')
            localValidateTS(tsc);
        else
            localValidateTSC(tsc);
        end %if isa(tsc,'timeseries')
    end

    % *********************************************************************
    % Validate that the time series collection object is OK.  Error if it isn't
    function localValidateTSC(tsc)

        tsNames = gettimeseriesnames(tsc);
        numTS = length(tsNames);
        for iTS = 1:numTS
            localValidateTS(get(tsc,tsNames{iTS}));
        end % for iTS
    end %localValidateTSCData

    % *********************************************************************
    % Validate that the time series object is OK.  Error if it isn't
    function localValidateTS(ts)
        if (ndims(ts.Data) > 2 || size(ts.Data,2) > 1)
            error('daq:putdata:tsmustbevector','Time series objects used with PUTDATA may only contain a single vector of data to be output.');
        end
        if ~ts.IsTimeFirst
            error('daq:putdata:timenotfirst','TS or time series objects in TSC must have IsTimeFirst set to 1.');
        end
    end %localValidateTS
end %putdata