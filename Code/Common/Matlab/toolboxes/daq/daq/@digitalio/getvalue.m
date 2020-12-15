function out = getvalue(obj)
%GETVALUE Return line values to MATLAB workspace.
%
%    OUT = GETVALUE(OBJ) returns values from digital I/O object, OBJ,
%    to OUT.  OBJ can be either a digital I/O object or a digital I/O
%    line.  If OBJ is a digital I/O object, then the values of the lines
%    contained by the device object, OBJ, will be returned.  If OBJ is
%    a digital I/O line, then the value of only those lines specified 
%    will be returned.
%
%    The output value, OUT, is returned as a binvec value.  A binvec 
%    value is a binary vector which is written with the least significant 
%    bit (LSB) as the leftmost vector element and the most significant
%    bit (MSB) as the rightmost vector element.  A binvec value can be 
%    converted to a decimal value with the BINVEC2DEC function. If OBJ
%    is a digital I/O object then the LSB is OBJ.Line(1) and the MSB 
%    is OBJ.Line(end).
%
%    If the digital I/O object contains lines from a port-configurable
%    device, the data acquisition engine will read from all the lines
%    even if they are not contained by the device object, OBJ.  This is
%    an inherent restriction of a port-configurable device.
%
%    Example:
%       dio = digitalio('nidaq', 'Dev1');
%       hline = addline(dio, 0:7, 'in');
%       getvalue(dio)
%       getvalue(dio.Line(1:4))
%       out = getvalue(dio.Line(8:-1:1))
%
%    See also DIGITALIO, ADDLINE, PUTVALUE, BINVEC2DEC, DEC2BINVEC,
%    DAQHELP.
%

%    DTL 9-1-2004
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.6.2.7 $  $Date: 2008/09/08 20:12:04 $

% Check for device arrays.
if ( length(obj) > 1 )
    error('daq:getvalue:unexpected', 'OBJ must be a 1-by-1 digital I/O object or a digital I/O line array.');
end
 
% Check for an digital io  object.
if ~isa(obj, 'digitalio') 
    error('daq:getvalue:invalidobject', 'OBJ must be a 1-by-1 digital I/O object or a digital I/O line array.');
end

% Determine if the object is valid.
if ~all(isvalid(obj))
    error('daq:getvalue:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Get the value.
uddobj = daqgetfield(obj,'uddobject');
out = getvalue(uddobj);
