function output = daqfind(obj, varargin)
%DAQFIND Find data acquisition objects with specified property values.
%
%    OUT = DAQFIND returns an array, OUT, of any analog input, analog  
%    output or digital I/O objects currently existing in the data acquisition
%    engine.
%
%    OUT = DAQFIND('P1', V1, 'P2', V2,...) returns a cell array, OUT, of  
%    objects, channels or lines whose property values match those passed 
%    as PV pairs, P1, V1, P2, V2,... The PV pairs can be specified as a 
%    cell array. 
%
%    OUT = DAQFIND(S) returns a cell array, OUT, of objects, channels or
%    lines whose property values match those defined in structure S whose 
%    field names are object property names and the field values are the
%    requested property values.
%   
%    OUT = DAQFIND(OBJ, 'P1', V1, 'P2', V2,...) restricts the search for 
%    matching PV pairs to the objects listed in OBJ and the channels or
%    lines contained by them.  OBJ can be an array or cell array of objects.
%
%    Note that it is permissible to use PV string pairs, structures, 
%    and PV cell array pairs in the same call to DAQFIND.
%
%    In any given call to DAQFIND, only device object properties or 
%    channel/line properties can be specified.  
%
%    When a property value is specified, it must use the same format as
%    GET returns.  For example, if GET returns the ChannelName as 'Left',
%    DAQFIND will not find an object with a ChannelName property value of
%    'left'.  However, properties which have an enumerated list data type,
%    will not be case sensitive when searching for property values.  For
%    example, DAQFIND will find an object with a Running property value
%    of 'On' or 'on'.  The data type of a property can be determined with
%    PROPINFO's Constraint field.
%
%    Example:
%      ai = analoginput('winsound');
%      addchannel(ai, [1 2], {'Left', 'Right'});
%      out = daqfind('Units', 'Volts')
%      out = daqfind({'ChannelName', 'Units'}, {'Left', 'Volts'})
%
%    See also PROPINFO, DAQDEVICE/GET.
%

%    DTL 9-1-2004
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.12.2.6 $  $Date: 2008/06/16 16:34:59 $

% Search for matching PV pairs.

% Degenerate case...
% When doing a daqfind with a daqchild object as ANY parameter, we end up
% here when we should have been going through daq\daqfind. This problem shows
% up when user does things like:
%    daqfind('Channel',ai.Channel)
%    daqfind( <cell array>, 'Channel' ai.Channel ), etc
% Call the privateFind function which is where we should have ended up.
if ( ~isobject(obj) )
    output = daqgate('privateFind', obj, varargin{:});
% Normal case...
else    
    % Search for matching PV pairs.
    output = daqgate('privateFindObj', obj, varargin{:});
end
