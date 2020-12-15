function [snapshot, metadata] = getsnapshot(obj)
%GETSNAPSHOT Immediately return a single image snapshot.
% 
%    FRAME = GETSNAPSHOT(OBJ) immediately returns one single image frame, 
%    FRAME, from the video input object, OBJ. The frame of data 
%    returned is independent of the FramesPerTrigger property, and has no 
%    effect on the FramesAvailable or FramesAcquired property.
% 
%    OBJ must be a 1x1 video input object.
% 
%    FRAME is returned as a H-by-W-by-B matrix, where 
%        
%         H   Image height, as specified in the ROIPosition property
%         W   Image width, as specified in the ROIPosition property
%         B   Number of color bands, as specified in the NumberOfBands property
%
%    FRAME is returned to the MATLAB workspace in its native data type using the 
%    color space specified by the ReturnedColorSpace property.
%
%    You can use the MATLAB IMAGE or IMAGESC function to view the returned 
%    data.
%
%    [FRAME, METADATA] = GETSNAPSHOT(OBJ) returns METADATA, an
%    1-by-1 array of structures. This structure contains information about the corresponding
%    FRAME. Each adaptor may choose to add its own set of METADATA. 
%    
%    If OBJ is Running but not Logging, and has been configured with
%    a hardware trigger, a timeout error will occur.
%    
%    It is possible to issue a ^C (Control-C) while GETSNAPSHOT is
%    blocking. This will return control to MATLAB.
%
%    Example:
%       % Construct a video input object associated 
%       % with a Matrox device at ID 1:
%       obj = videoinput('matrox', 1);
%
%       % Acquire and display a single image frame:
%       frame = getsnapshot(obj);
%       image(frame);
%
%       % Remove the video input object from memory:
%       delete(obj);
%
%    For more examples, see demoimaq_GetSnapshot.m
%
%    See also IMAQHELP, IMAQDEVICE/PEEKDATA, IMAQDEVICE/GETDATA.

%    CP 9-01-01
%    Copyright 2001-2010 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'imaqdevice')
    error(message('imaq:getsnapshot:invalidType'));
elseif (length(obj) > 1)
    error(message('imaq:getsnapshot:OBJ1x1'));
elseif ~isvalid(obj)
    error(message('imaq:getsnapshot:invalidOBJ'));
end

% Get single frame.
try
    [snapshot, metadata] = getsnapshot(imaqgate('privateGetField', obj, 'uddobject'));
catch exception
    throw(exception);
end