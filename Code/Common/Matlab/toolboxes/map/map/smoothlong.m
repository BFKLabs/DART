function lon = smoothlong(~, ~) %#ok<STOUT>
%SMOOTHLONG Remove discontinuities in longitude data
%
%   SMOOTHLONG has been removed.  Use unwrapMultipart instead.  Note that
%   unwrapMultipart requires its input to be in radians. When working in
%   degrees, use radtodeg(unwrapMultipart(degtorad(lon))).
%
%   NEWLON = SMOOTHLONG(LON) unwraps a row or column vector of
%   longitudes, azimuths, or phase angles.  Input and output are both in
%   degrees.
%
%   NEWLON = SMOOTHLONG(LON, ANGLEUNITS) works in the units defined by
%   the string ANGLEUNITS, which can be either 'degrees' or 'radians'.
%   ANGLEUNITS may be abbreviated and is case-insensitive.
%
%   See also unwrapMultipart

% Copyright 1996-2013 The MathWorks, Inc.

error(message('map:removed:smoothlong', 'SMOOTHLONG', 'unwrapMultipart',...
    'unwrapMultipart', 'radtodeg(unwrapMultipart(degtorad(lon)))'))
