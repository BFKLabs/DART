function privateDeleteFromJava(jobj)
% PRIVATEDELETEFROMJAVA Delete a Java object that is a videoinput object.
%
%   PRIVATEDELTEFROMJAVA(OBJ) deletes the object OBJ.  OBJ should be a Java
%   object created from a videoinput object, for example the object
%   created by PRIVATECREATEJAVAOBJECT.
%
%   PRIVATEDELETEFROMJAVA is a helper function that is designed to be
%   called from Java code.
%
%   See also privateCreateJavaObject.

%    DT 11/2004
%    Copyright 2004 The MathWorks, Inc.

obj = privateUDDToMATLAB(jobj);
delete(obj)