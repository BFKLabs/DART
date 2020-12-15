function putsample(obj,data)
%PUTSAMPLE Immediately output single sample to channel group.
%
%    PUTSAMPLE(OBJ, DATA) immediately outputs a row vector, DATA, containing
%    one sample for each channel contained by analog output object, OBJ.
%    OBJ must be a 1-by-1 analog output object.
%
%    PUTSAMPLE is valid for analog output processes only and can be called 
%    when OBJ is not running.
%
%    PUTSAMPLE is not supported for sound cards.
% 
%    See also DAQHELP, PUTDATA.
%

%    DTL 9-1-2004   
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.12.2.8 $  $Date: 2008/08/08 12:50:43 $


% Check for device arrays.
if ( length(obj) > 1 )
    error('daq:putsample:unexpected', 'OBJ must be a 1-by-1 analog output object.');
end
 
% Check for an analog input object.
if ~isa(obj, 'analogoutput') 
    error('daq:putsample:invalidobject', 'OBJ must be a 1-by-1 analog output object.');
end

% Determine if the object is valid.
if ~all(isvalid(obj))
    error('daq:putsample:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Check for numeric sample data.
if ~isnumeric(data)
    error('daq:putsample:invaliddata', 'DATA must be either double or native numeric values.');
end

uddobj = daqgetfield(obj,'uddobject');  
putsample(uddobj,data);
