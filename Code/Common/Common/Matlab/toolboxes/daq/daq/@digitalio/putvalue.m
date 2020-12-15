function putvalue(obj, data)
%PUTVALUE Write line values.
%
%    PUTVALUE(OBJ,DATA) write the data, DATA, to the digital I/O lines,
%    OBJ, or to the lines contained by digital I/O object, OBJ.
% 
%    DATA can be specified as either a decimal or a binvec value.   
%    A binvec value is a binary vector which is written with the  
%    least significant bit (LSB) as the leftmost vector element and 
%    the most significant bit (MSB) as the rightmost vector element.
%    If OBJ is a digital I/O object then the LSB is OBJ.Line(1) and
%    the MSB is OBJ.Line(end).
%
%    If OBJ is a digital I/O object which contains lines from a port-
%    configurable device then all lines will be written to even if they 
%    are not contained by the device object.  This is an inherent 
%    restriction of a port-configurable device.
%
%    An error will be returned if data is written to an input line.
%
%    If a decimal value is written to a digital I/O object and the value
%    is too large to be represented by the object, then an error is 
%    returned.  Otherwise the word is padded with zeros.
%
%    Example:
%       dio = digitalio('nidaq', 'Dev1');
%       hline = addline(dio, 0:3, 'out');
%       putvalue(dio, 8)
%       putvalue(dio, [0 0 0 0])
%       putvalue(dio.Line(1:4), [0 1 0 1])
%
%    See also DIGITALIO, ADDLINE, GETVALUE, BINVEC2DEC, DEC2BINVEC,
%    DAQHELP.
%

%    DTL 9-1-2004
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.7.2.9 $  $Date: 2008/09/08 20:12:05 $

% Check for device arrays.
if ( length(obj) > 1 )
    error('daq:putvalue:unexpected', 'OBJ must be a 1-by-1 digital I/O object or a digital I/O line array.');
end
 
% Check for a digital io object.
if ~isa(obj, 'digitalio') 
    error('daq:putvalue:invalidobject', 'OBJ must be a 1-by-1 digital I/O object or a digital I/O line array.');
end

% Determine if the object is valid.
if ~all(isvalid(obj))
    error('daq:putvalue:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Check the class of data.
if ( isempty(data) || (~isnumeric(data) && ~islogical(data)))
    error('daq:putvalue:invaliddata', 'DATA must be a positive numeric value or a binvec.');
end

% Output the data.
uddobj = daqgetfield(obj,'uddobject');
putvalue(uddobj, data);