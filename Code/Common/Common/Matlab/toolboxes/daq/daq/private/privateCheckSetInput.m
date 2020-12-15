function privateCheckSetInput(prop)
% PRIVATECHECKSETINPUT Verify SET property is valid.
%
%    PRIVATECHECKSETINPUT(PROP) throws an error if the specified
%    property, PROP.
%

%    PRIVATECHECKSETINPUT is a helper function for daqdevice\set and
%    daqchild\set.

%    MP 8-04-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.7.2.5 $  $Date: 2008/06/16 16:35:59 $

% Error if PROP is empty.
% Error if PROP is not a cell, structure or string.
if (isempty(prop) && ~ischar(prop)) ||...
   (~(iscell(prop) || isstruct(prop) || ischar(prop)))
   error('daq:privateCheckSetInput:invalidinput',...
       'Invalid parameter/value pair arguments.');
end
