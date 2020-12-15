function obj = ctranspose(obj)
% ' Complex conjugate transpose.   
% 
%    B = CTRANSPOSE(OBJ) is called for the syntax OBJ' (complex conjugate
%    transpose) when OBJ is a device object array or channel or line.
%

%    MP 12-22-98   
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.5.2.5 $  $Date: 2004/12/01 19:46:57 $

% Error if an invalid handle was passed.
if ~all(isvalid(obj))
   error('daq:transpose:invalidobject','One of the objects is invalid and cannot be transposed.');
end

% Transpose the device object vector.
uddobject = daqgetfield(obj, 'uddobject');
obj = daqsetfield(obj, 'uddobject', uddobject'); 