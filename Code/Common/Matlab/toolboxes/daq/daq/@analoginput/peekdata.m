function data=peekdata(obj,varargin)
%PEEKDATA Preview most recent acquired data.
%
%    PEEKDATA(OBJ,SAMPLES)
%    DATA = PEEKDATA(OBJ,SAMPLES) returns the latest number of samples 
%    specified by SAMPLES to DATA.  If SAMPLES is greater than the number of
%    samples currently acquired, all available samples will be returned 
%    with a warning message stating that the requested number of samples 
%    were not available.  OBJ must be a 1-by-1 analog input object.
%
%    DATA = PEEKDATA(OBJ,SAMPLES,TYPE) allows for DATA to be 
%    returned as the data type specified by the string TYPE.  TYPE can either
%    be 'double', for data to be returned as doubles, or 'native', for data 
%    to be returned in its native data type.  If TYPE is not specified, 
%    'double' is used as the default.
%
%    PEEKDATA is an non-blocking function that immediately returns data
%    samples and execution control to the MATLAB workspace.  Not all
%    requested data may be returned.
%
%    OBJ's SamplesAvailable property value will not be affected by the
%    number of samples returned by PEEKDATA.  This means that PEEKDATA
%    only looks at the data, it does not remove the data from the data 
%    acquisition engine.
%
%    PEEKDATA can be used only after the START command is issued and while
%    OBJ is running. PEEKDATA may also be called once after OBJ has stopped
%    running.
%
%    See also DAQHELP, GETDATA, GETSAMPLE, PROPINFO, DAQDEVICE/START.
%

%    DTL 9-1-2004
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.11.2.6 $  $Date: 2008/06/16 16:34:43 $

ArgChkMsg = nargchk(2,3,nargin);
if ~isempty(ArgChkMsg)
    error('daq:peekdata:argcheck', ArgChkMsg);
end

% Check for device arrays.
if length(obj) > 1
   error('daq:peekdata:invalidobject', 'OBJ must be a 1-by-1 analog input object.');
end

% Check for an analog input object.
if ~isa(obj, 'analoginput') 
   error('daq:peekdata:invalidobject', 'OBJ must be a 1-by-1 analog input object.');
end

% Determine if the object is valid.
if ~all(isvalid(obj))
   error('daq:peekdata:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Error if SAMPLES is not a non-negative numeric scalar.
if ( nargin > 1 )
    samples = varargin{1};
    if ~isnumeric(samples) || ~isscalar(samples) || samples < 0
       error('daq:peekdata:invalidsamples', 'SAMPLES must be a non-negative scalar value.');
    end
end

% Error if TYPE is not string.
if ( nargin > 2 )
    type = varargin{2};
    if ~ischar(type)
        error('daq:peekdata:invalidtype', 'TYPE must be a string value.');
    end
end

% Get the requested samples.
uddobj = daqgetfield(obj, 'uddobject');
data = peekdata(uddobj, varargin{:});
