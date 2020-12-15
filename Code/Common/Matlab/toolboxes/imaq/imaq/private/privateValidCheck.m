function isok = privateValidCheck(obj)
%PRIVATEVALIDCHECK True for image acquisition objects associated with hardware.
%
%    OUT = PRIVATEVALIDCHECK(OBJ) returns a logical array, OUT, that contains a 1 
%    where the elements of OBJ are image acquisition objects associated 
%    with hardware and a 0 where the elements of OBJ are image acquisition 
%    objects not associated with hardware.
%
%    See also IMAQDEVICE/ISVALID.
%

%    CP 9-01-01
%    Copyright 2001-2004 The MathWorks, Inc.

% Verify UDD object is valid.
uddObject = privateGetField(obj, 'uddobject');
isok = ishandle(uddObject);

% Return the correct shape based on the input size.
isok = reshape(isok, size(uddObject));