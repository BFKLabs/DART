function jobj = privateCreateJavaObject(adaptor, deviceID, format)
% PRIVATECREATEJAVAOBJECT Create a VIDEOINPUT for use in Java.
%
%   OUT = PRIVATECREATEJAVAOBJECT(ADAPTOR, DEVICEID, FORMAT) creates a
%   VIDEOINPUT object with the constructor arguments ADAPTOR, DEVICEID, and
%   FORMAT, and returns the resulting object as a Java object.
%
%   This method is a helper method for creating VIDEOINPUT objects from
%   Java code.
%
%   See also videoinput.

%    DT 11/2004
%    Copyright 2004 The MathWorks, Inc.

obj = videoinput(adaptor, deviceID, format);
sobj = struct(obj);
jobj = java(sobj.uddobject);