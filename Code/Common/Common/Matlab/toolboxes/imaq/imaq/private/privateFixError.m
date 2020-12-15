function newException = privateFixError(oldException)
%PRIVATEFIXERROR Remove any extra carriage returns.
%
%    newException = PRIVATEFIXERROR(oldException) removes any trailing 
%    CR's from the MException oldException and returns a new MException 
%    newException.

%    CP 9-01-01
%    Copyright 2001-2007 The MathWorks, Inc.

% Remove the trailing carraige returns and return the new exception.
newMessage = deblank(oldException.message);
newException = MException(oldException.identifier, newMessage);