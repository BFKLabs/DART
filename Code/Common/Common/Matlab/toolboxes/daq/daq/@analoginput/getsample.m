function samples=getsample(obj)
%GETSAMPLE Immediately acquire single sample.
%
%    OUT = GETSAMPLE(OBJ) returns a row vector, OUT, containing one 
%    immediate sample of data from each channel contained by the 
%    1-by-1 analog input object, OBJ.  The samples returned are not 
%    removed from the data acquisition engine.
%
%    GETSAMPLE is valid for analog input processes only and can be
%    called when OBJ is not running.  
%
%    GETSAMPLE can be used with sound cards only if the object, OBJ, is 
%    running.
% 
%    See also DAQHELP, PEEKDATA, GETDATA.
%

%    DTL 9-1-2004   
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.13.2.7 $  $Date: 2008/08/08 12:50:41 $

% GETSAMPLE does not accept device arrays.

% Check for device arrays.
if ( length(obj) > 1 )
   error('daq:getsample:unexpected', 'OBJ must be a 1-by-1 analog input object.');
end
 
% Check for an analog input object.
if ~isa(obj, 'analoginput') 
   error('daq:getsample:invalidobject', 'OBJ must be a 1-by-1 analog input object.');
end

% Determine if the object is valid.
if ~all(isvalid(obj))
   error('daq:getsample:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

uddobj = daqgetfield(obj,'uddobject');  
samples = getsample(uddobj);
