function [lat,lon] = interpm(lat,lon,maxdiff,method,units)
%INTERPM  Densify latitude-longitude sampling in lines or polygons
%
%  [lat,lon] = INTERPM(lat,long,maxdiff) linearly interpolates between
%  vector data coordinate points where necessary to return data with no
%  two connected points separated by an angular distance greater than
%  maxdiff. Maxdiff must be in the same units as the input lat and lon
%  data.
%
%  [lat,lon] = INTERPM(lat,long,maxdiff,'method') interpolates between
%  vector data coordinate points using a specified interpolation method.
%  Valid interpolation methods strings are 'gc' for great circle, 'rh'
%  for rhumb lines, and 'lin' for linear interpolation. With no units
%  specified, lat,long and maxdiff are assumed to be in units of degrees.
%
%  [lat,lon] = INTERPM(lat,long,maxdiff,'method','units') interpolates
%  between vector data coordinate points using a specified interpolation
%  method. Inputs and outputs are in the specified units.
%
%  See also INTRPLAT, INTRPLON, RESIZEM.

% Copyright 1996-2011 The MathWorks, Inc.

error(nargchk(3, 5, nargin, 'struct'))

if ~isequal(size(lat),size(lon))
    error(message('map:validate:inconsistentSizes2','INTERPM','LAT','LON'))
end

validateattributes(maxdiff, {'double'}, {'scalar'}, 'INTERPM', 'MAXDIFF', 3)

lat = ignoreComplex(lat, 'interpm', 'lat');
lon = ignoreComplex(lon, 'interpm', 'lon');
maxdiff = ignoreComplex(maxdiff, 'interpm', 'maxdiff');

if nargin < 4
    method = 'lin';
else
    method = validatestring(method, {'gc','rh','lin'}, 'INTERPM', 'METHOD', 4);
end

if nargin < 5
    units = 'degrees';
else
    units = checkangleunits(units);
end

[lat, lon] = doInterpm(lat,lon,maxdiff,method,units);
