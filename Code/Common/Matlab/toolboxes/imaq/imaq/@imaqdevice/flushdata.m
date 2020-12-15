function flushdata(obj, varargin)
%FLUSHDATA Remove buffered image frames from memory.
% 
%    FLUSHDATA(OBJ) removes all buffered image frames from 
%    memory. OBJ can be a single video input object or an 
%    array of video input objects.
% 
%    FLUSHDATA(OBJ,MODE) removes all buffered image frames from 
%    memory where MODE can be either of the following values:
%
%    'all'       Removes all data from the object and sets the
%                FramesAvailable property to 0 for the video  
%                input object, OBJ. This is the default mode 
%                when none is specified, FLUSHDATA(OBJ).
%
%    'triggers'  Removes all the data acquired during one 
%                trigger. TriggerRepeat must be greater than  
%                0 and FramesPerTrigger must not be set to Inf.
% 
%    See also IMAQHELP, IMAQDEVICE/GETDATA, IMAQDEVICE/PEEKDATA, 
%             IMAQDEVICE/PROPINFO.

%    RDD 8-02-02
%    Copyright 2001-2010 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'imaqdevice')
    error(message('imaq:flushdata:invalidType'));
elseif ~all(isvalid(obj)),
    % There are invalid objects.
    % Find all invalid indexes.
    inval_OBJ_indexes = find(isvalid(obj) == false);

    % Generate an error message specifying the index for the first invalid
    % object found.
    error(message('imaq:flushdata:invalidOBJ', inval_OBJ_indexes(1)));
elseif nargin>1 && ~ischar(varargin{1}),
    error(message('imaq:flushdata:invalidMode'));
end

% flush data.
try
    flushdata(imaqgate('privateGetField', obj, 'uddobject'),varargin{:});
catch exception
    throw(exception);
end